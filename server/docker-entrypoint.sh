#!/bin/sh
set -e

# 1) Aplica as migrations de schema (NUNCA o seed de desenvolvimento).
#    Idempotente: pula o que já foi aplicado via schema_migrations.
if [ "${RUN_MIGRATIONS:-true}" = "true" ]; then
  echo "[entrypoint] Aplicando migrations..."
  /app/bin/migrate
fi

# 2) Cria/atualiza o admin de produção quando ADMIN_SENHA estiver definida.
#    Rode uma vez; depois pode remover a variável se preferir.
if [ -n "${ADMIN_SENHA}" ]; then
  echo "[entrypoint] Garantindo admin de produção..."
  /app/bin/create_admin || echo "[entrypoint] create_admin falhou (seguindo mesmo assim)."
fi

# 3) Sobe o servidor (usa PORT injetado pelo Render).
echo "[entrypoint] Iniciando servidor..."
exec /app/bin/server
