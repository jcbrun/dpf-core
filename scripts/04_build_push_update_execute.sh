#!/usr/bin/env bash

### Nom du script : scripts/04_build_push_update_execute.sh (local build/test)
### Utile pour tester avant de s’appuyer sur GitHub Actions.

set -euo pipefail

ENV_NAME=${1:-}
MODE=${2:-docker}   # docker | cloudbuild
TAG=${3:-}          # optional

if [[ -z "${ENV_NAME}" ]]; then
  echo "Usage: $0 <dev|rec|prod> [docker|cloudbuild] [tag]"
  exit 1
fi

# shellcheck disable=SC1091
source ./scripts/01_env.sh "${ENV_NAME}"

TAG="${TAG:-$(git rev-parse --short HEAD 2>/dev/null || echo local)}"
IMAGE="${REGION}-docker.pkg.dev/${PROJECT_ID}/${DBT_ARTEFACT_REGISTRY}/dbt:${TAG}"

echo "=== Build/Push/Deploy/Run env=${ENV_NAME} ==="
echo "PROJECT_ID=${PROJECT_ID}"
echo "IMAGE=${IMAGE}"
echo "MODE=${MODE}"

if [[ "${MODE}" == "cloudbuild" ]]; then
  gcloud builds submit --project "${PROJECT_ID}" --tag "${IMAGE}" .
else
  gcloud auth configure-docker "${REGION}-docker.pkg.dev" --quiet
  docker build -t "${IMAGE}" .
  docker push "${IMAGE}"
fi

gcloud run jobs update "${DBT_JOB_CLOUDRUN}" \
  --project "${PROJECT_ID}" \
  --region "${REGION}" \
  --image "${IMAGE}" \
  --service-account "${SA_RUNNER_EMAIL}" \
  --set-env-vars "PROJECT_ID=${PROJECT_ID},DATASET=${DATASET},BQ_LOCATION=${BQ_LOCATION},DBT_CMD=${DBT_CMD_DEFAULT}" \
  --task-timeout 3600 \
  --max-retries 1

gcloud run jobs execute "${DBT_JOB_CLOUDRUN}" \
  --project "${PROJECT_ID}" \
  --region "${REGION}" \
  --wait

gcloud run jobs executions list \
  --job "${DBT_JOB_CLOUDRUN}" \
  --project "${PROJECT_ID}" \
  --region "${REGION}" \
  --limit 5

echo "=== OK env=${ENV_NAME} ==="
