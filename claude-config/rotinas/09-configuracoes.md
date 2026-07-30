# Rotina 09 — Configurações (parâmetros de runtime via tela)

## Objetivo

Tela restrita a `ADMIN` para ajustar parâmetros não sensíveis que hoje vêm do
`.env`, com auditoria de quem alterou e quando — sem reescrever o arquivo
`.env` em disco (ver `PLANO_IMPLEMENTACAO.md`, seção 2.8, para a justificativa
dessa decisão de segurança).

## Depende de

- `00-fundacao-infra.md`
- `01-autenticacao.md` — necessário para checar papel `ADMIN`.

## Pode rodar em paralelo com

`02-cadastro-setores.md`, `04-cadastro-tipos-equipamento.md`, `06-servicos-ti.md`,
`08-relatorios.md` — não depende de nenhuma delas.

## Escopo — Banco

Tabela `configuracoes (chave, valor, descricao, tipo, atualizado_em,
atualizado_por)` já criada na rotina 00.

## Escopo — Servidor

- `GET /configuracoes` — retorna apenas as chaves da lista permitida (ver
  abaixo), nunca segredos.
- `PUT /configuracoes/:chave` — restrito a `ADMIN`; grava `atualizado_por`
  (usuário autenticado) e `atualizado_em`; valida `tipo` (string/int/bool)
  antes de persistir.
- **Lista fixa de chaves editáveis pela tela** (definir em código, não no
  banco, para não abrir brecha de criar chaves sensíveis via API): ex.
  `LOG_LEVEL`, `PAGINACAO_PADRAO`, mensagens padrão do sistema. `DB_PASSWORD`,
  `DB_USER`, `DB_HOST`, `JWT_SECRET` e afins **nunca** entram nessa lista —
  continuam só em `.env`.

## Escopo — Mobile

- Feature `configuracoes/`: tela restrita a `ADMIN`, formulário por chave
  (input adequado ao `tipo`: texto, número, switch).

## Regras de negócio

- Toda alteração é auditada (quem, quando, valor anterior se possível).
- Nenhuma chave sensível é sequer retornada por `GET /configuracoes`.

## Critérios de aceite

- [ ] Chaves sensíveis (`DB_*`, `JWT_SECRET`) nunca aparecem na resposta da
      API nem na tela.
- [ ] Alteração de uma chave permitida reflete em runtime sem reiniciar o
      servidor (para os parâmetros que fizerem sentido, ex. `LOG_LEVEL`).
- [ ] Toda alteração fica registrada com usuário e data.
- [ ] Acesso restrito a `ADMIN` (outros papéis recebem 403).

## Consultar

Skills: `dart-shelf-server` (seção Configuração via `.env` + tabela
`configuracoes`), `flutter-mvvm-arquitetura`.
