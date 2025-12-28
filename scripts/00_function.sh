#!/usr/bin/env bash

### Nom du script : scripts/00_function.sh

set -euo pipefail

# Create Service Account (idempotent) - NO JSON KEYS (OIDC/WIF only)
create_sa () {
  local PROJECT_ID=$1
  local SA=$2
  local SA_EMAIL=$3
  local SA_DISPLAY=${4:-"$SA $PROJECT_ID"}

  echo "Function create_sa: PROJECT_ID=${PROJECT_ID} SA=${SA} SA_EMAIL=${SA_EMAIL}"

  if gcloud iam service-accounts describe "${SA_EMAIL}" --project "${PROJECT_ID}" >/dev/null 2>&1; then
    echo "SA ${SA_EMAIL} already exists (ok)"
  else
    gcloud iam service-accounts create "${SA}" \
      --display-name "${SA_DISPLAY}" \
      --project "${PROJECT_ID}"
  fi
}

# Assign project IAM role (idempotent-ish)
assign_role () {
  local PROJECT_ID=$1
  local TYPE=$2
  local USER=$3
  local ROLE=$4

  echo "Function assign_role: PROJECT_ID=${PROJECT_ID} MEMBER=${TYPE}:${USER} ROLE=${ROLE}"

  gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member="${TYPE}:${USER}" \
    --role="${ROLE}" \
    >/dev/null
}
