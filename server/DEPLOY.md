# Deploy — SATI-UUA (Render + Neon)

Servidor Dart/Shelf no **Render** (Docker) + Postgres no **Neon.tech**.

## Visão geral

- O banco vive no **Neon** e é acessado por uma única `DATABASE_URL` com `?sslmode=require`.
- O **Render** builda o `server/Dockerfile` e roda o container.
- No boot, o container aplica as **migrations** (schema, sem seed de dev) e,
  se `ADMIN_SENHA` estiver definida, cria/atualiza o **admin de produção**.

---

## 1. Neon.tech — banco

1. Crie um projeto no Neon (região próxima da do Render, ex.: US East).
2. Em **Connection Details**, copie a connection string (papel *pooled* ou
   *direct* servem). Formato:
   ```
   postgresql://user:senha@ep-xxx.us-east-2.aws.neon.tech/dbname?sslmode=require
   ```
3. Garanta que ela termina em `?sslmode=require`.

## 2. Render — serviço web

### Opção A — Blueprint (recomendado)
1. Faça push do repositório com o `render.yaml` (na raiz) e o `server/Dockerfile`.
2. Render → **New → Blueprint** → selecione o repositório.
3. Preencha as variáveis marcadas como `sync: false`:
   - `DATABASE_URL` = a URL do Neon.
   - `ADMIN_LOGIN` = ex. `admin`.
   - `ADMIN_SENHA` = uma senha forte (usada só no 1º boot).
   - `JWT_SECRET` é gerado automaticamente.

### Opção B — Manual
1. Render → **New → Web Service** → conecte o repo.
2. **Root Directory:** `server` · **Runtime:** Docker · **Health Check Path:** `/health`.
3. Em **Environment**, adicione:
   | Variável        | Valor                                   |
   |-----------------|-----------------------------------------|
   | `DATABASE_URL`  | URL do Neon (`...?sslmode=require`)      |
   | `JWT_SECRET`    | string longa e aleatória                 |
   | `APP_ENV`       | `production`                             |
   | `ADMIN_LOGIN`   | `admin`                                  |
   | `ADMIN_SENHA`   | senha forte (só no 1º deploy)            |

## 3. Primeiro deploy

O `docker-entrypoint.sh` roda automaticamente, na ordem:
1. `migrate` — cria/atualiza o schema (idempotente).
2. `create_admin` — só se `ADMIN_SENHA` existir.
3. inicia o servidor na porta `PORT` (injetada pelo Render).

Verifique em `https://<seu-servico>.onrender.com/health` → deve responder
`{"status":"ok","db":"ok"}`.

Depois do 1º boot bem-sucedido, você pode **remover `ADMIN_SENHA`** das env vars
(o admin já está no banco). Nunca deixe a senha em texto no repositório.

## 4. Alternativa: rodar migrations do seu PC

Você tem `psql` local. Para aplicar o schema no Neon sem depender do boot:

```bash
cd server
# Exporte a URL do Neon (Git Bash / Linux / macOS):
export DATABASE_URL="postgresql://user:senha@ep-xxx.aws.neon.tech/dbname?sslmode=require"
dart run tool/migrate.dart        # só schema (sem --seed em produção!)
ADMIN_SENHA="senha-forte" dart run tool/create_admin.dart
```

No PowerShell:
```powershell
$env:DATABASE_URL="postgresql://user:senha@ep-xxx.aws.neon.tech/dbname?sslmode=require"
dart run tool/migrate.dart
$env:ADMIN_SENHA="senha-forte"; dart run tool/create_admin.dart
```

## 5. App mobile / web

Aponte o cliente Flutter para `https://<seu-servico>.onrender.com`
(o baseUrl da API). O CORS já permite qualquer origem — se quiser restringir,
edite `lib/src/middlewares/cors_middleware.dart`.

## Notas

- **Plano free do Render** hiberna após inatividade (~15 min); o primeiro
  request depois disso demora alguns segundos (cold start).
- O seed de desenvolvimento (`admin.ti` / `admin123`) **não** é aplicado em
  produção — use `create_admin` para o admin real.
- Uploads de anexos ficam no disco efêmero do container; no plano free eles se
  perdem a cada redeploy. Para persistir, use um Render Disk ou storage externo.
