#!/usr/bin/env bash

### Nom du script : scripts/03_bootstrap_prereq.sh
### Ce script met en place les prérequis CI/CD + Docker + Cloud Run Job sur un environnement :
###   - APIs
###   - service accounts builder/runner
###   - rôles IAM
###   - Artifact Registry
###   - Workload Identity Federation (pool+provider + condition)
###   - binding repo GitHub → SA_BUILDER
###   - création du Cloud Run Job (avec image placeholder)

set -euo pipefail

ENV_NAME=${1:-}
if [[ -z "${ENV_NAME}" ]]; then
  echo "Usage: $0 <dev|rec|prod>"
  exit 1
fi

# shellcheck disable=SC1091
source ./scripts/00_function.sh
# shellcheck disable=SC1091
source ./scripts/01_env.sh "${ENV_NAME}"

echo "=== Bootstrap prereqs env=${ENV_NAME} project=${PROJECT_ID} ==="

# 1) APIs
gcloud services enable \
  artifactregistry.googleapis.com \
  run.googleapis.com \
  iam.googleapis.com \
  sts.googleapis.com \
  cloudbuild.googleapis.com \
  --project "${PROJECT_ID}"

# 2) Service Accounts (no JSON keys)
create_sa "${PROJECT_ID}" "${SA_BUILDER}" "${SA_BUILDER_EMAIL}" "GitHub builder ${ENV_NAME}"
create_sa "${PROJECT_ID}" "${SA_RUNNER}"  "${SA_RUNNER_EMAIL}"  "Cloud Run runner ${ENV_NAME}"

# 3) IAM roles for SA_BUILDER (used by GitHub Actions)
assign_role "${PROJECT_ID}" serviceAccount "${SA_BUILDER_EMAIL}" roles/artifactregistry.writer
assign_role "${PROJECT_ID}" serviceAccount "${SA_BUILDER_EMAIL}" roles/run.developer
# needed to deploy job with --service-account=SA_RUNNER_EMAIL
assign_role "${PROJECT_ID}" serviceAccount "${SA_BUILDER_EMAIL}" roles/iam.serviceAccountUser

# 4) IAM roles for SA_RUNNER (Cloud Run Job runtime)
assign_role "${PROJECT_ID}" serviceAccount "${SA_RUNNER_EMAIL}" roles/bigquery.jobUser
assign_role "${PROJECT_ID}" serviceAccount "${SA_RUNNER_EMAIL}" roles/bigquery.dataEditor
assign_role "${PROJECT_ID}" serviceAccount "${SA_RUNNER_EMAIL}" roles/secretmanager.secretAccessor

# 5) Artifact Registry (idempotent)
if ! gcloud artifacts repositories describe "${DBT_ARTEFACT_REGISTRY}" \
  --location "${REGION}" \
  --project "${PROJECT_ID}" >/dev/null 2>&1; then
  gcloud artifacts repositories create "${DBT_ARTEFACT_REGISTRY}" \
    --repository-format=docker \
    --location="${REGION}" \
    --project "${PROJECT_ID}"
else
  echo "Artifact Registry ${DBT_ARTEFACT_REGISTRY} exists (ok)"
fi

# 6) WIF pool (idempotent)
if ! gcloud iam workload-identity-pools describe "${REPO_POOL_ID}" \
  --location global \
  --project "${PROJECT_ID}" >/dev/null 2>&1; then
  gcloud iam workload-identity-pools create "${REPO_POOL_ID}" \
    --location global \
    --project "${PROJECT_ID}" \
    --display-name "GitHub Actions Pool (${ENV_NAME})"
else
  echo "WIF pool ${REPO_POOL_ID} exists (ok)"
fi

# 7) WIF provider condition
# - dev/rec: allow repo on any ref
# - prod: recommended strict: allow only tag refs starting v*
ATTRIBUTE_CONDITION="attribute.repository == '${REPO_OWNER}/${REPO_NAME}'"
if [[ "${ENV_NAME}" == "prod" ]]; then
  ATTRIBUTE_CONDITION="attribute.repository == '${REPO_OWNER}/${REPO_NAME}' && startsWith(attribute.ref, 'refs/tags/v')"
fi

# create or update provider
if ! gcloud iam workload-identity-pools providers describe "${REPO_PROVIDER_ID}" \
  --location global \
  --workload-identity-pool "${REPO_POOL_ID}" \
  --project "${PROJECT_ID}" >/dev/null 2>&1; then

  gcloud iam workload-identity-pools providers create-oidc "${REPO_PROVIDER_ID}" \
    --project "${PROJECT_ID}" \
    --location global \
    --workload-identity-pool "${REPO_POOL_ID}" \
    --display-name "GitHub OIDC Provider (${ENV_NAME})" \
    --issuer-uri "https://token.actions.githubusercontent.com" \
    --attribute-mapping "google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.ref=assertion.ref" \
    --attribute-condition "${ATTRIBUTE_CONDITION}"
else
  gcloud iam workload-identity-pools providers update-oidc "${REPO_PROVIDER_ID}" \
    --project "${PROJECT_ID}" \
    --location global \
    --workload-identity-pool "${REPO_POOL_ID}" \
    --display-name "GitHub OIDC Provider (${ENV_NAME})" \
    --attribute-mapping "google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.ref=assertion.ref" \
    --attribute-condition "${ATTRIBUTE_CONDITION}"
fi

# 8) Bind GitHub repo identity to SA_BUILDER
gcloud iam service-accounts add-iam-policy-binding "${SA_BUILDER_EMAIL}" \
  --project "${PROJECT_ID}" \
  --role roles/iam.workloadIdentityUser \
  --member "principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${REPO_POOL_ID}/attribute.repository/${REPO_OWNER}/${REPO_NAME}" \
  >/dev/null || true

# 9) Create Cloud Run Job if absent (placeholder image)
IMAGE_PLACEHOLDER="${REGION}-docker.pkg.dev/${PROJECT_ID}/${DBT_ARTEFACT_REGISTRY}/dbt:bootstrap"

if ! gcloud run jobs describe "${DBT_JOB_CLOUDRUN}" \
  --project "${PROJECT_ID}" \
  --region "${REGION}" >/dev/null 2>&1; then

  gcloud run jobs create "${DBT_JOB_CLOUDRUN}" \
    --project "${PROJECT_ID}" \
    --region "${REGION}" \
    --image "${IMAGE_PLACEHOLDER}" \
    --service-account "${SA_RUNNER_EMAIL}" \
    --set-env-vars "PROJECT_ID=${PROJECT_ID},DATASET=${DATASET},BQ_LOCATION=${BQ_LOCATION},DBT_CMD=${DBT_CMD_DEFAULT}" \
    --task-timeout 3600 \
    --max-retries 1

  echo "Cloud Run Job created with placeholder image (will be updated by CI/CD)."
else
  echo "Cloud Run Job ${DBT_JOB_CLOUDRUN} exists (ok)"
fi

echo "=== SUMMARY env=${ENV_NAME} ==="
echo "PROJECT_ID=${PROJECT_ID}"
echo "REGION=${REGION}"
echo "GAR_REPO=${DBT_ARTEFACT_REGISTRY}"
echo "JOB=${DBT_JOB_CLOUDRUN}"
echo "SA_BUILDER_EMAIL=${SA_BUILDER_EMAIL}"
echo "SA_RUNNER_EMAIL=${SA_RUNNER_EMAIL}"
echo "WIF_PROVIDER=${REPO_WIF_PROVIDER}"
