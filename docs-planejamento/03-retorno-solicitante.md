# Planejamento — Retorno do Solicitante (Informações Adicionais)

**Versão:** 1.0  
**Data:** 2026-07-31  
**Escopo:** Tela de detalhe do chamado — solicitante pode adicionar informações após abertura

---

## Objetivo

Permitir que o usuário que abriu o chamado acrescente informações adicionais
após a abertura, sem precisar abrir um novo chamado. Cada adição fica registrada
como uma entrada na timeline (histórico), identificada como "Informação do Solicitante".

---

## Diferença em relação ao histórico de atendimento

| | Histórico de Atendimento | Retorno do Solicitante |
|--|--|--|
| **Quem escreve** | Atendente / Admin | Solicitante (dono do chamado) |
| **Aparece na timeline** | Sim | Sim |
| **Pode encerrar chamado** | Sim | Não |
| **Campo "data de retorno"** | Sim | Não |
| **Identificação visual** | Ícone de atendente | Ícone de usuário / cor distinta |

---

## Impacto por camada

### Banco de dados

A tabela `chamado_historico` precisa de um ajuste para suportar entradas do solicitante:

```sql
-- Migration: 0003_historico_solicitante.sql

-- 1. Tornar usuario_responsavel_id nullable (era NOT NULL)
ALTER TABLE chamado_historico
  ALTER COLUMN usuario_responsavel_id DROP NOT NULL;

-- 2. Novo campo para identificar o autor (solicitante)
ALTER TABLE chamado_historico
  ADD COLUMN usuario_solicitante_id bigint REFERENCES usuarios(id) ON DELETE RESTRICT;

-- 3. Constraint: exatamente um dos dois deve ser preenchido
ALTER TABLE chamado_historico
  ADD CONSTRAINT chk_historico_autor
    CHECK (
      (usuario_responsavel_id IS NOT NULL AND usuario_solicitante_id IS NULL) OR
      (usuario_responsavel_id IS NULL AND usuario_solicitante_id IS NOT NULL)
    );

-- 4. Tipo de registro para facilitar queries
ALTER TABLE chamado_historico
  ADD COLUMN tipo_registro text NOT NULL DEFAULT 'ATENDIMENTO'
    CHECK (tipo_registro IN ('ATENDIMENTO', 'RETORNO_SOLICITANTE'));
```

**Alternativa mais simples (sem breaking change):**
Adicionar apenas `tipo_registro` e `usuario_solicitante_id` como nullable,
sem alterar `usuario_responsavel_id`. A constraint garante consistência.

> **Recomendação:** usar a alternativa simples para não quebrar código existente.

### Server

#### `models/chamado_historico.dart`
```dart
final int? responsavelId;          // era required int
final String? responsavelNome;     // era required String
final int? solicitanteId;          // novo
final String? solicitanteNome;     // novo
final String tipoRegistro;         // 'ATENDIMENTO' | 'RETORNO_SOLICITANTE'
```

Campo calculado:
```dart
String get autorNome => responsavelNome ?? solicitanteNome ?? '—';
bool get eRetornoSolicitante => tipoRegistro == 'RETORNO_SOLICITANTE';
```

#### `repositories/chamado_historico_repository.dart`
- `listByChamado`: JOIN com `usuarios u2 ON u2.id = h.usuario_solicitante_id`
- Novo método `registrarRetornoSolicitante({required int chamadoId, required int solicitanteId, required String descricao})`
  - Insere com `tipo_registro = 'RETORNO_SOLICITANTE'`, `usuario_responsavel_id = NULL`
  - Não muda situação do chamado
  - Não aceita `marca_encerramento`

#### `routes/chamados_route.dart`
Novo endpoint:

```
POST /chamados/:id/retorno-solicitante
Body: { "descricao": "..." }
Papel: qualquer (mas apenas o próprio solicitante do chamado pode usar)
```

**Validação:** `payload.userId == chamado.solicitanteId` — caso contrário, 403.

### Flutter

#### `chamado_detalhe_dto.dart` — `ChamadoHistoricoDto`
```dart
final int? responsavelId;
final String? responsavelNome;
final int? solicitanteId;
final String? solicitanteNome;
final String tipoRegistro;

String get autorNome => responsavelNome ?? solicitanteNome ?? '—';
bool get eRetornoSolicitante => tipoRegistro == 'RETORNO_SOLICITANTE';
```

#### `chamado_detalhe_view.dart` — `_DetalheBody`
Lógica de exibição do formulário:

```dart
final encerrado = chamado.situacao == SituacaoChamado.encerrado;
final isSolicitante = user?.papel == PapelUsuario.solicitante;
final isSolicitanteDoChamado = user?.id == chamado.solicitanteId;

// Formulário de retorno do SOLICITANTE
final formSolicitante = (!encerrado && isSolicitante && isSolicitanteDoChamado)
    ? _RetornoSolicitanteForm(...)
    : null;

// Formulário de atendimento do ATENDENTE (já existente)
final formAtendente = (!encerrado && isAtendente) ? _RegistroForm(...) : null;
```

#### Novo widget `_RetornoSolicitanteForm`
- Campos: apenas `Descrição` (textarea)
- Botão: "Enviar Informação"
- Não tem campo de data, não tem checkbox de encerramento
- Após envio, recarrega a timeline

#### `_TimelineItem` — diferenciação visual
```dart
// Ícone/cor diferente conforme tipo
final color = item.eRetornoSolicitante
    ? AppColors.accent300   // azul mais claro
    : AppColors.accent500;  // azul padrão

// Label identificador
if (item.eRetornoSolicitante)
  Text('Informação do Solicitante', style: TextStyle(color: ..., fontSize: 11))
```

#### `chamado_detalhe_view_model.dart`
Novo método:
```dart
Future<bool> enviarRetornoSolicitante({
  required int chamadoId,
  required String descricao,
})
```

#### `chamado_repository.dart`
Novo método em `ChamadoRepositoryBase`:
```dart
Future<ChamadoDetalheDto> enviarRetornoSolicitante({
  required int chamadoId,
  required String descricao,
});
```

---

## Regras de negócio

| Regra | Detalhe |
|-------|---------|
| Só o próprio solicitante pode adicionar | Verificado no servidor (`userId == chamado.solicitanteId`) |
| Chamado encerrado → bloqueado | Nem atendente nem solicitante podem adicionar |
| Não encerra o chamado | `tipo_registro = 'RETORNO_SOLICITANTE'` não altera `situacao` |
| Aparece na timeline cronológica | Intercalado com histórico do atendente |
| Admin pode sempre visualizar | Sem restrição de leitura |

---

## Pontos de decisão para validação

1. **Chamado aguardando solicitante** — Quando atendente marca `AGUARDANDO_SOLICITANTE`,
   ao solicitante enviar retorno, a situação deve voltar automaticamente para `EM_ANDAMENTO`?
2. **Notificação** — O atendente deve ser notificado quando o solicitante enviar retorno?
   (Integra com o planejamento do sininho — doc 04)
3. **Admin pode adicionar retorno como solicitante?** — Não faz sentido; admin usa o
   formulário de atendimento.
