#!/usr/bin/env bash

### Nom du script : scripts/08_dbt_create_profiles.sh
### Crée le répertoire profiles/ dans le projet dbt et le profiles.yml adapté Cloud Run + ADC.

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

echo "=== Create profiles for dbt project: ${DBT_PROJECT} ==="

mkdir -p "${DBT_PROJECT}/profiles"

cat > "${DBT_PROJECT}/profiles/profiles.yml" <<EOF
${DBT_PROJECT}:
  target: "{{ env_var('DBT_TARGET', 'dev') }}"
  outputs:
    dev:
      type: bigquery
      method: oauth
      project: "{{ env_var('PROJECT_ID') }}"
      dataset: "{{ env_var('DATASET') }}"
      location: "{{ env_var('BQ_LOCATION', 'EU') }}"
      threads: 4
      timeout_seconds: 300
    rec:
      type: bigquery
      method: oauth
      project: "{{ env_var('PROJECT_ID') }}"
      dataset: "{{ env_var('DATASET') }}"
      location: "{{ env_var('BQ_LOCATION', 'EU') }}"
      threads: 4
      timeout_seconds: 300
    prod:
      type: bigquery
      method: oauth
      project: "{{ env_var('PROJECT_ID') }}"
      dataset: "{{ env_var('DATASET') }}"
      location: "{{ env_var('BQ_LOCATION', 'EU') }}"
      threads: 4
      timeout_seconds: 300
EOF

echo "Created: ${DBT_PROJECT}/profiles/profiles.yml"
echo "NOTE: Cloud Run uses ADC via service account runtime (method: oauth)."
