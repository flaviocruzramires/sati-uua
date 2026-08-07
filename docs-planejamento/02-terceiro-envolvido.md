# Planejamento — Campo "Envolve Terceiro" no Chamado

**Versão:** 1.0  
**Data:** 2026-07-31  
**Escopo:** Tabela `chamados` + tela de abertura + detalhe do chamado

---

## Objetivo

Permitir que o atendente indique, durante o atendimento, se o chamado envolve um
fornecedor, prestador de serviço ou outro terceiro externo, registrando o nome desse
terceiro para rastreabilidade.

---

## Decisão de design

O campo é preenchido **pelo atendente** (não pelo solicitante), pois é uma informação
de diagnóstico técnico. O solicitante pode ver o campo no detalhe, mas não edita.

---

## Impacto por camada

### Banco de dados — `ALTER TABLE chamados`

```sql
-- Migration: 0002_add_terceiro.sql
ALTER TABLE chamados
  ADD COLUMN envolve_terceiro boolean NOT NULL DEFAULT false,
  ADD COLUMN nome_terceiro    text;

-- Constraint: nome_terceiro obrigatório quando envolve_terceiro = true
ALTER TABLE chamados
  ADD CONSTRAINT chk_terceiro
    CHECK (envolve_terceiro = false OR nome_terceiro IS NOT NULL);
```

### Server

#### `models/chamado.dart`
```dart
final bool envolveTerceiro;
final String? nomeTerceiro;
```

Adicionado ao `toJson()`:
```dart
'envolveTerceiro': envolveTerceiro,
'nomeTerceiro': nomeTerceiro,
```

#### `repositories/chamado_repository.dart`
- `_selectCols`: adicionar `c.envolve_terceiro, c.nome_terceiro`
- `_fromRow`: mapear os dois novos campos (índices 14 e 15)
- Novo método `atualizarTerceiro({required int id, required bool envolveTerceiro, String? nomeTerceiro})`

#### `routes/chamados_route.dart`
Novo endpoint:

```
PATCH /chamados/:id/terceiro
Body: { "envolveTerceiro": true, "nomeTerceiro": "Empresa XYZ" }
Papel mínimo: ATENDENTE
```

Retorna o chamado atualizado.

### Flutter

#### `chamado_dto.dart`
```dart
final bool envolveTerceiro;
final String? nomeTerceiro;
```

#### `chamado_detalhe_view.dart` — `_ResumoCard`
- Se `chamado.envolveTerceiro == true`, exibir linha extra:
  - Kicker: "Terceiro Envolvido"
  - Valor: `chamado.nomeTerceiro`
- Se `false`, não exibir (não polui o resumo)

#### `chamado_detalhe_view.dart` — `_RegistroForm` (somente atendente)
Adicionar seção colapsável "Terceiro envolvido?" abaixo da data de retorno:

```
[ ] Envolve terceiro
    └── (visível só se marcado) Nome do terceiro: ___________
```

- Widget: `AppCheckboxRow` + `AppTextField` condicional
- Ao salvar atendimento, se houve mudança no terceiro, dispara também
  `PATCH /chamados/:id/terceiro`
- Não é campo obrigatório; atendente pode deixar desmarcado

#### `chamado_detalhe_view_model.dart`
Novo método:
```dart
Future<void> atualizarTerceiro({
  required bool envolveTerceiro,
  String? nomeTerceiro,
})
```
Chama `PATCH /chamados/:id/terceiro` e recarrega o detalhe.

---

## Comportamento

| Ação | Quem pode | Quando |
|------|-----------|--------|
| Marcar "envolve terceiro" | Atendente / Admin | Chamado não encerrado |
| Ver campo no detalhe | Todos | Sempre (se marcado) |
| Alterar após encerramento | Nenhum | Bloqueado |

---

## Exibição no Relatório

No módulo de relatórios, adicionar coluna "Terceiro" (Sim/Não) e filtro
"Apenas com terceiro = Sim" — implementação futura, não neste sprint.

---

## Pontos de decisão para validação

1. **Quem preenche** — Confirmado: atendente. Ou o solicitante também deveria indicar
   isso ao abrir o chamado?
2. **Múltiplos terceiros** — A proposta é texto livre (um nome). Precisamos de múltiplos
   terceiros por chamado, ou um campo texto único é suficiente?
3. **Histórico de mudanças do campo** — Registrar no `chamado_historico` quando o
   campo mudar? Ex.: "Atendente marcou: envolve terceiro — Empresa XYZ"
