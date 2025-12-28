#!/usr/bin/env bash

### Nom du script : scripts/09_dbt_create_docker_assets.sh
### Crée un entrypoint.sh + Dockerfile dans le projet dbt choisi.

set -euo pipefail

DBT_PROJECT="${1:-}"
if [[ -z "${DBT_PROJECT}" ]]; then
  echo "Usage: $0 <DBT_PROJECT>"
  exit 1
fi

if [[ ! -d "${DBT_PROJECT}" ]]; then
  echo "Project dir ${DBT_PROJECT} not found."
  exit 1
fi

echo "=== Create Docker assets for dbt project: ${DBT_PROJECT} ==="

cat > "${DBT_PROJECT}/entrypoint.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

echo "DBT_VERSION:"
dbt --version

echo "DBT_DEPS:"
dbt deps --quiet || true

echo "DBT_DEBUG:"
dbt debug

DBT_CMD="${DBT_CMD:-dbt build}"
echo "RUN: ${DBT_CMD}"
bash -lc "${DBT_CMD}"
EOF

chmod +x "${DBT_PROJECT}/entrypoint.sh"

cat > "${DBT_PROJECT}/Dockerfile" <<'EOF'
FROM python:3.12-slim

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
 && rm -rf /var/lib/apt/lists/*

# Reproductible : versions fixées
RUN pip install --no-cache-dir dbt-core==1.10.3 dbt-bigquery==1.10.3

COPY . /app
ENV DBT_PROFILES_DIR=/app/profiles

RUN chmod +x /app/entrypoint.sh
ENTRYPOINT ["/app/entrypoint.sh"]
EOF

echo "Created: ${DBT_PROJECT}/entrypoint.sh"
echo "Created: ${DBT_PROJECT}/Dockerfile"
