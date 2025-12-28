#!/usr/bin/env bash

### Nom du script : scripts/07_dbt_init_project.sh
### Permet de créer plusieurs projets dbt dans le même repo (tu passes le nom via DBT_PROJECT).

set -euo pipefail

DBT_PROJECT="${1:-}"
if [[ -z "${DBT_PROJECT}" ]]; then
  echo "Usage: $0 <DBT_PROJECT>"
  echo "Example: $0 uc_02"
  exit 1
fi

if [[ -d "${DBT_PROJECT}" ]]; then
  echo "Directory ${DBT_PROJECT} already exists. Aborting."
  exit 1
fi

# requires dbt installed (see scripts/06_dbt_install.sh)
if ! command -v dbt >/dev/null 2>&1; then
  echo "dbt not found. Please run: ./scripts/06_dbt_install.sh"
  exit 1
fi

echo "=== Initialize dbt project: ${DBT_PROJECT} ==="

mkdir -p "${DBT_PROJECT}"
pushd "${DBT_PROJECT}" >/dev/null

# dbt init is interactive; we run it with defaults.
# If you prefer fully non-interactive, create dbt_project.yml manually.
dbt init "${DBT_PROJECT}"

popd >/dev/null

echo "OK. Project created in: ${DBT_PROJECT}/"
