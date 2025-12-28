#!/usr/bin/env bash

### Nom du script : scripts/02_create_project.sh
### Optionnel : à utiliser si les projets DEV/REC/PROD ne sont pas déjà créés.

set -euo pipefail

ENV_NAME=${1:-}
if [[ -z "${ENV_NAME}" ]]; then
  echo "Usage: $0 <dev|rec|prod>"
  exit 1
fi

# shellcheck disable=SC1091
source ./scripts/01_env.sh "${ENV_NAME}"

ORG_ID=$(gcloud organizations list --format="value(ID)" | head -n 1)
BILLING_ID=$(gcloud beta billing accounts list --format="value(name)" | head -n 1)

echo "Creating project ${PROJECT_ID} (env=${ENV_NAME})"
echo "ORG_ID=${ORG_ID}"
echo "BILLING_ID=${BILLING_ID}"

if gcloud projects describe "${PROJECT_ID}" >/dev/null 2>&1; then
  echo "Project ${PROJECT_ID} already exists (ok)"
else
  gcloud projects create "${PROJECT_ID}" --organization="${ORG_ID}" --name="${PROJECT_ID}"
  gcloud billing projects link "${PROJECT_ID}" --billing-account="${BILLING_ID}"
fi

echo "Done."
