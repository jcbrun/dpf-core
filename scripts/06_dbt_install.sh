#!/usr/bin/env bash

### Nom du script : scripts/06_dbt_install.sh
### Installe dbt en local (python/venv) de façon reproductible.

set -euo pipefail

DBT_VERSION_CORE="${DBT_VERSION_CORE:-1.10.3}"
DBT_VERSION_BIGQUERY="${DBT_VERSION_BIGQUERY:-1.10.3}"

echo "=== Install dbt locally (core=${DBT_VERSION_CORE}, bigquery=${DBT_VERSION_BIGQUERY}) ==="

python3 -m venv .venv
# shellcheck disable=SC1091
source .venv/bin/activate

python -m pip install --upgrade pip
pip install --no-cache-dir "dbt-core==${DBT_VERSION_CORE}" "dbt-bigquery==${DBT_VERSION_BIGQUERY}"

dbt --version

echo ""
echo "OK. To activate later:"
echo "  source .venv/bin/activate"
