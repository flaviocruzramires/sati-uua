# ---- Build stage: compila servidor + tools em executáveis nativos ----
FROM dart:stable AS build

WORKDIR /app

# Resolve dependências primeiro (cache de camadas).
COPY pubspec.* ./
RUN dart pub get

# Copia o restante do código e compila.
COPY . .
RUN dart pub get --offline
RUN dart compile exe bin/server.dart        -o /app/bin/server \
 && dart compile exe tool/migrate.dart       -o /app/bin/migrate \
 && dart compile exe tool/create_admin.dart  -o /app/bin/create_admin

# ---- Runtime stage: imagem enxuta com os binários + psql para migrations ----
FROM debian:bookworm-slim AS runtime

# postgresql-client fornece o `psql` usado pela migração.
# ca-certificates é necessário para o SSL do Neon.
RUN apt-get update \
    && apt-get install -y --no-install-recommends postgresql-client ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Os binários de `dart compile exe` são autossuficientes (embutem o runtime
# Dart) — precisam só da libc, presente no debian-slim. Não copiamos `/runtime/`
# (isso seria para aot-snapshot + dartaotruntime, e ainda conflita com o
# symlink /lib do merged-/usr do bookworm).
COPY --from=build /app/bin/ /app/bin/
# migrate.dart procura os .sql via Platform.script -> parent/parent/migrations,
# ou seja, /app/migrations quando o binário está em /app/bin.
COPY migrations ./migrations
COPY docker-entrypoint.sh /app/docker-entrypoint.sh
RUN chmod +x /app/docker-entrypoint.sh

# O Render injeta PORT; expomos 8080 como padrão local.
EXPOSE 8080

ENTRYPOINT ["/app/docker-entrypoint.sh"]
