# Planejamento — Sistema de Notificações (Sininho)

**Versão:** 1.0  
**Data:** 2026-07-31  
**Escopo:** Banco + Server + Flutter (tela de avisos + sininho)

---

## Objetivo

Implementar um sistema de notificações in-app acessível pelo ícone de sino na topbar.
Cada papel recebe notificações relevantes ao seu contexto. O usuário clica na notificação
e é direcionado ao chamado correspondente.

---

## Regras por papel

| Papel | O que dispara notificação |
|-------|--------------------------|
| **Solicitante** | Atendente assumiu o chamado; atendente registrou retorno; chamado encerrado |
| **Atendente** | Novo chamado aberto (sem responsável); solicitante enviou retorno em chamado do atendente |
| **Admin** | Todos os eventos acima de todos os usuários |

---

## Impacto por camada

### Banco de dados — nova tabela `notificacoes`

```sql
-- Migration: 0004_notificacoes.sql

CREATE TABLE notificacoes (
  id              bigserial PRIMARY KEY,
  usuario_id      bigint NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  chamado_id      bigint NOT NULL REFERENCES chamados(id) ON DELETE CASCADE,
  tipo            text NOT NULL,
  -- 'CHAMADO_ASSUMIDO' | 'RETORNO_ATENDENTE' | 'CHAMADO_ENCERRADO'
  -- 'NOVO_CHAMADO' | 'RETORNO_SOLICITANTE'
  mensagem        text NOT NULL,
  lida            boolean NOT NULL DEFAULT false,
  criada_em       timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_notificacoes_usuario ON notificacoes(usuario_id, lida, criada_em DESC);
CREATE INDEX idx_notificacoes_chamado ON notificacoes(chamado_id);
```

### Tipos de notificação

| Tipo | Gatilho | Destinatário |
|------|---------|--------------|
| `NOVO_CHAMADO` | `POST /chamados` | Todos os atendentes + admins |
| `CHAMADO_ASSUMIDO` | `PUT /chamados/:id` (atribuir responsável) | Solicitante do chamado |
| `RETORNO_ATENDENTE` | `POST /chamados/:id/historico` | Solicitante do chamado |
| `RETORNO_SOLICITANTE` | `POST /chamados/:id/retorno-solicitante` | Atendente responsável + admins |
| `CHAMADO_ENCERRADO` | Histórico com `marcaEncerramento=true` | Solicitante do chamado |

### Server

#### `models/notificacao.dart` (novo)
```dart
class Notificacao {
  final int id;
  final int usuarioId;
  final int chamadoId;
  final String tipo;
  final String mensagem;
  final bool lida;
  final DateTime criadaEm;

  Map<String, dynamic> toJson() => { ... };
}
```

#### `repositories/notificacao_repository.dart` (novo)
```dart
class NotificacaoRepository {
  // Cria notificações para uma lista de usuários
  Future<void> criar({
    required List<int> usuarioIds,
    required int chamadoId,
    required String tipo,
    required String mensagem,
  });

  // Lista notificações do usuário (últimas 50, não lidas primeiro)
  Future<List<Notificacao>> listByUsuario(int usuarioId);

  // Conta não lidas (para o badge do sino)
  Future<int> countNaoLidas(int usuarioId);

  // Marca como lida
  Future<void> marcarLida(int id);

  // Marca todas como lidas
  Future<void> marcarTodasLidas(int usuarioId);
}
```

#### `services/notificacao_service.dart` (novo)
Serviço que encapsula a lógica de "quem notificar" para cada evento:

```dart
class NotificacaoService {
  // Chamado pelo handler de POST /chamados
  Future<void> notificarNovoChamado(int chamadoId, String descricao);

  // Chamado pelo handler de PUT /chamados/:id (assumir)
  Future<void> notificarChamadoAssumido(int chamadoId, String atendenteNome);

  // Chamado pelo handler de POST /chamados/:id/historico
  Future<void> notificarRetornoAtendente(int chamadoId, String atendenteNome);

  // Chamado pelo handler de POST /chamados/:id/retorno-solicitante
  Future<void> notificarRetornoSolicitante(int chamadoId, String solicitanteNome);

  // Chamado quando marca_encerramento = true
  Future<void> notificarChamadoEncerrado(int chamadoId);
}
```

**Busca de destinatários:**
- `NOVO_CHAMADO`: `SELECT id FROM usuarios WHERE papel IN ('ATENDENTE','ADMIN') AND ativo = true`
- `CHAMADO_ASSUMIDO` / `RETORNO_ATENDENTE` / `CHAMADO_ENCERRADO`: `SELECT usuario_solicitante_id FROM chamados WHERE id = ?`
- `RETORNO_SOLICITANTE`: `SELECT usuario_responsavel_id FROM chamados WHERE id = ?` + todos os admins

#### `routes/notificacoes_route.dart` (novo)

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/notificacoes` | Lista notificações do usuário autenticado |
| `GET` | `/notificacoes/count` | Retorna `{ "naoLidas": N }` (para o badge) |
| `PATCH` | `/notificacoes/:id/lida` | Marca uma como lida |
| `PATCH` | `/notificacoes/todas-lidas` | Marca todas como lidas |

### Flutter

#### Provider `notificacoesCountProvider`
```dart
// Conta não lidas para o badge
final notificacoesCountProvider = StreamProvider<int>((ref) {
  // Polling a cada 30 segundos
  return Stream.periodic(const Duration(seconds: 30))
      .asyncMap((_) => ref.read(notificacaoRepositoryProvider).countNaoLidas());
});
```

Ou via `FutureProvider` que é invalidado após ações relevantes (salvar histórico, etc.).

#### Badge no sino — `app_shell.dart`

Substituir o ícone estático por:
```dart
// No _Topbar e no AppBar mobile:
Stack(
  children: [
    IconButton(
      icon: const Icon(LucideIcons.bell),
      onPressed: () => context.go('/notificacoes'),
    ),
    if (count > 0)
      Positioned(
        right: 6, top: 6,
        child: Container(
          width: 16, height: 16,
          decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
          child: Text('$count', style: TextStyle(color: Colors.white, fontSize: 10)),
        ),
      ),
  ],
)
```

#### Tela `/notificacoes` — `NotificacoesView` (nova)
- Lista com `ListView` de cards de notificação
- Cada card mostra: mensagem, chamado #ID, data/hora, status (lida/não lida)
- Card não lido: fundo levemente destacado
- Clique: marca como lida + navega para `/chamados/:chamadoId`
- Botão no topo: "Marcar todas como lidas"
- Estado vazio: "Nenhuma notificação por enquanto"

#### `NotificacaoDto` (novo)
```dart
class NotificacaoDto {
  final int id;
  final int chamadoId;
  final String tipo;
  final String mensagem;
  final bool lida;
  final DateTime criadaEm;
}
```

#### `NotificacaoRepository` Flutter (novo)
```dart
abstract class NotificacaoRepositoryBase {
  Future<List<NotificacaoDto>> list();
  Future<int> countNaoLidas();
  Future<void> marcarLida(int id);
  Future<void> marcarTodasLidas();
}
```

#### Rota no router
```dart
GoRoute(path: '/notificacoes', builder: (_, __) => const NotificacoesView()),
```

#### Sidebar — nova entrada (opcional)
Pode ser acessada pelo sino ou adicionada ao sidebar sob "ANÁLISE":
```dart
NavEntry(
  icon: LucideIcons.bell,
  label: 'Notificações',
  route: '/notificacoes',
  group: 'ANÁLISE',
)
```

---

## Mensagens de notificação por tipo

| Tipo | Mensagem |
|------|----------|
| `NOVO_CHAMADO` | `"Novo chamado #ID: {descrição truncada}"` |
| `CHAMADO_ASSUMIDO` | `"Seu chamado #ID foi assumido por {atendenteNome}"` |
| `RETORNO_ATENDENTE` | `"O atendente {nome} registrou um retorno no chamado #ID"` |
| `RETORNO_SOLICITANTE` | `"O solicitante {nome} enviou informações no chamado #ID"` |
| `CHAMADO_ENCERRADO` | `"Seu chamado #ID foi encerrado"` |

---

## Fases de implementação sugeridas

| Fase | O que fazer |
|------|-------------|
| 1 | Migration `notificacoes` + `NotificacaoRepository` server |
| 2 | `NotificacaoService` + integração nos handlers existentes |
| 3 | Endpoints `GET/PATCH /notificacoes*` |
| 4 | Flutter: `NotificacaoDto` + repository + provider count |
| 5 | Flutter: badge no sino (topbar desktop + AppBar mobile) |
| 6 | Flutter: tela `NotificacoesView` com lista e navegação |

---

## Pontos de decisão para validação

1. **Polling vs. WebSocket** — A proposta usa polling a cada 30 s (simples, sem dependência extra).
   WebSocket seria tempo real mas adiciona complexidade. Polling é suficiente para o contexto?
2. **Retenção de notificações** — Manter por quanto tempo? Sugestão: 90 dias, depois purge automático via cron.
3. **Notificação `NOVO_CHAMADO` para todos os atendentes** — Com muitos atendentes isso gera
   muitos registros. Alternativa: notificar só admins para distribuição. Como prefere?
4. **Push notification mobile** — Por ora apenas in-app. Push via FCM é fase futura?
