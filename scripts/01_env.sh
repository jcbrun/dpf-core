#!/usr/bin/env bash

### Nom du script : scripts/01_env.sh
### ⚠️ À personnaliser : mettre les vrais PROJECT_ID DEV/REC/PROD et tes datasets.

set -euo pipefail

ENV_NAME=${1:-}
if [[ -z "${ENV_NAME}" ]]; then
  echo "Usage: source ./scripts/01_env.sh <dev|rec|prod>"
  return 1
fi

export ENV_NAME

# === Common settings ===
export REGION="europe-west9"
export BQ_LOCATION="EU"
export DBT_PROFILES_DIR="./profiles"

# === GitHub repo (source of identity) ===
export REPO_OWNER="jcbrun"
export REPO_NAME="dpf-client"

# WIF names (same logical names per project; provider/pool are created per project)
export REPO_POOL_ID="github-pool"
export REPO_PROVIDER_ID="github-provider"

# === Per environment / per project mapping ===
case "${ENV_NAME}" in
  dev)
    export PROJECT_ID="dpf-client-dev"      # <-- ⚠️ change
    export DATASET="clients_dev"            # <-- ⚠️ change
    export DBT_CMD_DEFAULT="dbt build"
    ;;
  rec)
    export PROJECT_ID="dpf-client-rec"      # <-- ⚠️ change
    export DATASET="clients_rec"            # <-- ⚠️ change
    export DBT_CMD_DEFAULT="dbt build"
    ;;
  prod)
    export PROJECT_ID="dpf-client-prod"     # <-- ⚠️ change
    export DATASET="clients_prod"           # <-- ⚠️ change
    export DBT_CMD_DEFAULT="dbt build"
    ;;
  *)
    echo "ENV_NAME must be dev|rec|prod"
    return 1
    ;;
esac

# === Derived variables ===
export PROJECT_NUMBER="$(gcloud projects describe "${PROJECT_ID}" --format="value(projectNumber)")"

export SA_ADMIN="sa-admin-${PROJECT_ID}"
export SA_ADMIN_EMAIL="${SA_ADMIN}@${PROJECT_ID}.iam.gserviceaccount.com"

export SA_BUILDER="sa-builder-${PROJECT_ID}"
export SA_BUILDER_EMAIL="${SA_BUILDER}@${PROJECT_ID}.iam.gserviceaccount.com"

export SA_RUNNER="sa-runner-${PROJECT_ID}"
export SA_RUNNER_EMAIL="${SA_RUNNER}@${PROJECT_ID}.iam.gserviceaccount.com"

export DBT_ARTEFACT_REGISTRY="ar-dbt-${PROJECT_ID}"
export DBT_JOB_CLOUDRUN="job-dbt-${PROJECT_ID}"

# WIF provider resource name (to store in GitHub secrets)
export REPO_WIF_PROVIDER="projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${REPO_POOL_ID}/providers/${REPO_PROVIDER_ID}"
