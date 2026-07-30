---
name: dart-shelf-server
description: Use this skill whenever writing or reviewing server-side Dart code (Shelf handlers, middlewares, routing, services, repositories, authentication, logging, configuration) in the Chamados de TI project backend.
---

# Servidor Dart (Shelf + shelf_router)

## Arquitetura em camadas

```
Router (shelf_router)
  → Handler/Controller   (parse request, chama Service, monta Response)
    → Service            (regra de negócio, transações)
      → Repository       (acesso a dados, SEMPRE com colunas explícitas)
        → package:postgres (pool de conexões)
```

Handlers nunca acessam o banco diretamente. Services nunca constroem `Response`
HTTP (retornam objetos de domínio ou lançam exceções de domínio, que um
middleware de erro converte em JSON).

## Injeção de dependência (composition root)

Sem framework de DI mágico — um único ponto de composição em `lib/src/di/`:

```dart
class AppContainer {
  final Pool dbPool;
  late final UsuarioRepository usuarioRepository;
  late final ChamadoRepository chamadoRepository;
  // ...
  late final AuthService authService;
  late final ChamadoService chamadoService;

  AppContainer(this.dbPool) {
    usuarioRepository = UsuarioRepository(dbPool);
    chamadoRepository = ChamadoRepository(dbPool);
    authService = AuthService(usuarioRepository, jwtSecret: Env.jwtSecret);
    chamadoService = ChamadoService(chamadoRepository, usuarioRepository);
  }
}
```

`bin/server.dart` monta o `AppContainer` uma vez e injeta nos handlers via
closures/`Router` — nenhum handler cria sua própria instância de repositório/serviço.

## Middlewares (pipeline sugerido, nessa ordem)

1. **Request ID** — gera/propaga um id único por requisição (usado no log).
2. **Logging** — loga rota, método, status, duração e request id
   (`package:logging`, nunca `print`).
3. **Error handling** — captura exceções de domínio e desconhecidas, converte
   em JSON padronizado (`{"error": {"code":..., "message":...}}`), nunca vaza
   stack trace para o cliente em produção.
3. **CORS** — necessário pois o Flutter web consumirá a API de uma origem
   diferente em desenvolvimento.
4. **Auth** — valida JWT (quando presente), popula o usuário autenticado no
   `context` do request para os handlers seguintes.

## Configuração via `.env` + tabela `configuracoes`

- `.env` (lido uma vez na subida do servidor, ex. com `package:dotenv` ou
  `envied`) contém segredos e parâmetros de infraestrutura: porta, credenciais
  de banco, `JWT_SECRET`.
- A tela "Configurações" (requisito 6.1) não reescreve o `.env` em disco —
  grava na tabela `configuracoes`, lida no boot e recarregada sob demanda
  (endpoint `PUT /configuracoes/:chave`, restrito a `ADMIN`, com log de
  auditoria de quem alterou e quando). Isso evita expor segredos via HTTP e
  evita a necessidade de reiniciar o processo para refletir mudanças simples
  (ex.: paginação padrão, mensagens do sistema).
- Documente claramente, no código e para o cliente, quais chaves são
  "somente `.env`" (segredos) vs. "editáveis pela tela" (parâmetros de negócio).

## Autenticação e autorização

- Login: valida `login`/`senha` (bcrypt) contra `usuarios`, emite JWT
  (`dart_jsonwebtoken`) com `sub` (id do usuário) e `papel` no payload,
  expiração curta + refresh (se necessário na Fase 1; pode começar só com
  expiração simples e evoluir).
- Middleware de auth injeta o usuário autenticado no contexto do request.
- Autorização por papel é verificada no **Service**, não no Handler nem no
  Repository (regra de negócio, não é responsabilidade de infraestrutura).

## Logging

- `package:logging`, um `Logger` por camada/arquivo (`Logger('ChamadoService')`).
- Nível configurável via `.env`/`configuracoes` (`LOG_LEVEL`).
- Nunca logar senha, hash de senha ou token JWT completo (logar no máximo os
  primeiros caracteres do token para correlação, se necessário).
- Toda requisição gera exatamente uma linha de log de acesso (via middleware),
  além de logs de negócio pontuais dentro dos Services quando relevante.

## Regra inegociável: nunca `SELECT *`

Todo método de repositório lista as colunas explicitamente, mesmo quando
"todas" as colunas são necessárias — isso protege contra quebras silenciosas
quando uma coluna é adicionada/removida e deixa explícito o contrato de dados.

```dart
// ERRADO
await conn.query('SELECT * FROM usuarios WHERE id = @id', {'id': id});

// CORRETO
await conn.query(
  'SELECT id, nome, email, login, setor_id, papel, ativo, criado_em '
  'FROM usuarios WHERE id = @id',
  {'id': id},
);
```

Antes de finalizar qualquer PR/tarefa no servidor, rode:
`grep -ri "select \*" server/lib` — deve retornar vazio.

## Paginação e listagens

Todo endpoint de listagem (`GET /chamados`, `GET /usuarios`, etc.) aceita
`page`/`pageSize` (ou `limit`/`offset`) e retorna `{"data": [...], "total": N}` —
nunca retorna a tabela inteira sem paginação, especialmente `chamados` e
`relatorios`.
