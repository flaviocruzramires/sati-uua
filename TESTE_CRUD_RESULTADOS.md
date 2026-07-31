# Resultados dos Testes CRUD — SATI-UUA

**Data:** 2026-07-30  
**Servidor:** http://localhost:8090  
**Usuário de teste:** admin.ti

---

## Resumo

| Categoria | Testes | OK | Conflito (esperado) |
|-----------|--------|----|---------------------|
| Setores | 3 | 1 (GET) | 2 (já existiam) |
| Tipos Equipamento | 3 | 1 (GET) | 2 (já existiam) |
| Equipamentos | 3 | 3 | 0 |
| Serviços | 3 | 3 | 0 |
| Usuários | 3 | 3 | 0 |
| Chamados | 3 | 3 | 0 |
| Dashboard | 1 | 1 | 0 |
| Relatório | 1 | 1 | 0 |
| **Total** | **20** | **16** | **4** |

> Os 4 "erros" são respostas 409 Conflict corretamente retornadas pelo servidor ao tentar
> inserir registros com nome duplicado (Setor e TipoEquipamento criados em rodada anterior).
> Não são bugs — validação de unicidade funcionando corretamente.

---

## Dados Criados

### Setores (existentes + criados)
| id | Nome |
|----|------|
| 1 | TI |
| 2 | (existente da seed) |
| 3 | Diretoria Academica |
| 4 | Laboratorio de Informatica |

### Tipos de Equipamento
| id | Nome |
|----|------|
| 1 | Impressora |
| 2 | Switch de Rede |

### Equipamentos
| id | Descrição | Tipo | Patrimônio | Localização |
|----|-----------|------|------------|-------------|
| 1 | HP LaserJet 1020 (rodada 1) | Impressora | PAT-001 | Secretaria |
| 2 | Switch 24 portas Cisco (rodada 1) | Switch de Rede | PAT-002 | Sala de Servidores |
| 5 | HP LaserJet 1020 (rodada 2) | Impressora | PAT-003 | Secretaria |
| 6 | Switch 24 portas Cisco 2 | Switch de Rede | PAT-004 | Sala de Servidores |

### Serviços
| id | Descrição |
|----|-----------|
| 1 | Manutencao de Impressora |
| 2 | Configuracao de Rede |
| 5 | Suporte a Hardware |
| 6 | Instalacao de Software |

### Usuários
| id | Nome | Login | Papel |
|----|------|-------|-------|
| 1 | Administrador TI | admin.ti | ADMIN |
| 3 | Carlos Atendente | carlos.atendente | ATENDENTE |
| 4 | Joao Solicitante | joao.solicitante | SOLICITANTE |
| 7 | Ana Atendente | ana.atendente | ATENDENTE |
| 8 | Pedro Solicitante | pedro.solicitante | SOLICITANTE |

### Chamados
| id | Descrição | Situação |
|----|-----------|----------|
| 1-5 | (criados em rodadas anteriores) | ABERTO |
| 6 | Impressora da secretaria nao imprime | ABERTO |
| 7 | Sem acesso a internet no laboratorio | ABERTO |

---

## Bugs Encontrados e Corrigidos

### 1. `authMiddleware` fora do pipeline global (CRÍTICO)
- **Causa:** O middleware de autenticação não estava registrado em `bin/server.dart`
- **Efeito:** Todos os endpoints protegidos retornavam 500 (`internal_error`)
- **Fix:** Adicionado `authMiddleware(container.authService)` ao pipeline; middleware
  atualizado para ignorar rotas públicas (`/auth/*`, `/health`)

### 2. `s.nome` → `s.descricao` nos chamados (SQL incorreto)
- **Causa:** `chamado_repository.dart` e `chamado_historico_repository.dart` referenciavam
  `s.nome` em `JOIN servicos s`, mas a tabela `servicos` tem coluna `descricao`
- **Efeito:** Todos os endpoints de chamados retornavam 500
- **Fix:** Substituído `s.nome` → `s.descricao` nos dois repositórios

### 3. Cast `num?` / `String` em AVG/EXTRACT (postgres v3)
- **Causa:** postgres v3 retorna resultados de `AVG(EXTRACT(...))` e `COALESCE(..., 0)` como
  `String` em vez de `num`, causando `type 'String' is not a subtype of type 'num?'`
- **Efeito:** Endpoints `/dashboard/resumo` e `/relatorios/chamados` retornavam 500
- **Fix:** Funções `_toDouble(Object? v)` e `_toInt(Object? v)` adicionadas em
  `dashboard_repository.dart` e `relatorio_repository.dart`

### 4. Sidebar itens ausentes (Flutter)
- **Causa:** `currentUserProvider` é `FutureProvider` assíncrono; durante o carregamento,
  `user?.papel ?? PapelUsuario.solicitante` resultava em papel `solicitante` e ocultava
  itens de admin/atendente no sidebar
- **Fix:** `AppShell.papelUsuario` tornado `PapelUsuario?`; `SidebarNavItem._visible`
  já retornava `true` quando `currentPapel == null` (mostra tudo durante loading);
  `UserFooterTile.papel` tornado nullable

### 5. RangeError no footer do sidebar
- **Causa:** `_iniciais` getter em `user_footer_tile.dart` fazia `''.split(' ')[0][0]`
  quando `nome == ''` (usuário ainda carregando)
- **Fix:** Filtro de partes vazias + fallback `'?'`

### 6. Logo FlutterLogo no sidebar
- **Fix:** Substituído por `Image.asset('assets/images/logo_sati_uua.jpg')` no header
  do `app_shell.dart`
