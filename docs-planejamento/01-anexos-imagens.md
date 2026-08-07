# Planejamento — Anexos e Imagens em Chamados

**Versão:** 1.0  
**Data:** 2026-07-31  
**Escopo:** Abertura de chamado + Retorno de atendimento + Retorno do solicitante

---

## Objetivo

Permitir que o usuário anexe prints/imagens diretamente no corpo do chamado ao abrir
e ao registrar retornos (tanto atendente quanto solicitante), mantendo os anexos
vinculados ao registro do histórico correspondente.

---

## Impacto por camada

### Banco de dados — nova tabela `chamado_anexos`

```sql
CREATE TABLE chamado_anexos (
  id              bigserial PRIMARY KEY,
  chamado_id      bigint NOT NULL REFERENCES chamados(id) ON DELETE CASCADE,
  historico_id    bigint REFERENCES chamado_historico(id) ON DELETE CASCADE,
  -- NULL = anexo da abertura; NOT NULL = anexo de um registro de histórico
  usuario_id      bigint NOT NULL REFERENCES usuarios(id) ON DELETE RESTRICT,
  nome_arquivo    text NOT NULL,
  tamanho_bytes   bigint NOT NULL,
  mime_type       text NOT NULL,
  caminho         text NOT NULL,  -- path relativo em disco (server/uploads/)
  criado_em       timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_chamado_anexos_chamado   ON chamado_anexos(chamado_id);
CREATE INDEX idx_chamado_anexos_historico ON chamado_anexos(historico_id);
```

**Regras:**
- `historico_id IS NULL` → anexo vinculado à abertura do chamado
- `historico_id IS NOT NULL` → anexo vinculado a um registro de histórico
- Máximo **5 anexos** por envio
- Tamanho máximo: **5 MB** por arquivo
- Tipos permitidos: `image/jpeg`, `image/png`, `image/webp`, `image/gif`

### Armazenamento de arquivos (server)

- Pasta: `server/uploads/chamados/<chamado_id>/`
- Nome em disco: `<uuid>.<ext>` (sem o nome original, evita colisões e path traversal)
- O `nome_arquivo` original é preservado apenas no banco para exibição

### Endpoints novos (server)

| Método | Rota | Descrição |
|--------|------|-----------|
| `POST` | `/chamados/:id/anexos` | Upload de um arquivo (multipart/form-data) |
| `GET` | `/chamados/:id/anexos` | Lista anexos do chamado (abertura + todos os históricos) |
| `GET` | `/anexos/:id/download` | Retorna o arquivo para download/visualização |
| `DELETE` | `/anexos/:id` | Remove um anexo (só quem enviou ou admin) |

**Parâmetros do POST:**
- `file` — arquivo binário (multipart)
- `historico_id` — (opcional) ID do registro de histórico ao qual vincular

### Flutter — mudanças

#### `abrir_chamado_view.dart`
- Adicionar widget `_AnexosField` com botão "Adicionar imagem"
- Permite selecionar até 5 arquivos via `image_picker` ou `file_picker`
- Exibe miniaturas com botão de remoção
- Fluxo: ao confirmar abertura, primeiro cria o chamado (`POST /chamados`),
  depois faz uploads individualmente (`POST /chamados/:id/anexos`)

#### `chamado_detalhe_view.dart` — `_RegistroForm`
- Mesma lógica de `_AnexosField`
- Após salvar o histórico, faz upload dos anexos com `historico_id`

#### `_TimelineItem`
- Se o item de histórico tiver anexos, exibir grade de miniaturas clicáveis
- Clique abre o anexo em tela cheia (`InteractiveViewer`) ou baixa se não for imagem

#### `_ResumoCard`
- Exibir seção "Anexos da abertura" se existirem

#### Novo provider `chamadoAnexosProvider`
- `FutureProvider` que busca `GET /chamados/:id/anexos`
- Invalidado após cada upload

### Dependências Flutter novas

```yaml
# pubspec.yaml
image_picker: ^1.1.2       # câmera + galeria (mobile)
file_picker: ^8.1.2        # seleção de arquivo (web/desktop)
cached_network_image: ^3.4.1  # cache de miniaturas
```

### Dependências server novas

```yaml
# pubspec.yaml
mime: ^2.0.0          # detecção de MIME type
uuid: ^4.4.2          # geração de nome em disco
shelf_multipart: ^2.0.0  # parsing de multipart/form-data
```

---

## Comportamento de segurança

- Somente usuários autenticados acessam downloads
- Atendente/Admin vê todos os anexos; Solicitante vê apenas os do próprio chamado
- Validação de MIME type no servidor (não confiar no Content-Type do cliente)
- Nomes de arquivo em disco são UUIDs — sem risco de path traversal
- Pasta `uploads/` fora do `lib/` e com `.gitignore`

---

## Fases de implementação sugeridas

| Fase | O que fazer |
|------|-------------|
| 1 | Migration `chamado_anexos` + endpoint upload/download/delete |
| 2 | Flutter: `_AnexosField` reutilizável + integração em Abrir Chamado |
| 3 | Flutter: integração em Registrar Atendimento (atendente) |
| 4 | Flutter: exibição de miniaturas na timeline e no resumo |
| 5 | Flutter: integração em Retorno do Solicitante (ver doc 04) |

---

## Pontos de decisão para validação

1. **Armazenamento local vs. S3/bucket** — A proposta usa disco local (`server/uploads/`).
   Para produção, considerar migrar para object storage (Minio, S3).
2. **Limite de tamanho** — 5 MB por arquivo adequado?
3. **Tipos aceitos** — apenas imagens, ou também PDF e outros documentos?
