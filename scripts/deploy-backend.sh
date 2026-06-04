#!/usr/bin/env bash
set -euo pipefail

ASG_NAME="${ASG_NAME:?ASG_NAME required}"
ECR_REPO="${ECR_REPOSITORY_URL:?ECR_REPOSITORY_URL required}"
AWS_REGION="${AWS_REGION:-us-east-1}"
IMAGE_TAG="${IMAGE_TAG:-latest}"

log()  { echo "[$(date +%T)] $*"; }
fail() { echo "[ERROR] $*" >&2; exit 1; }

log "Logging in to ECR..."
aws ecr get-login-password --region "$AWS_REGION" | \
  docker login --username AWS --password-stdin "$ECR_REPO"

log "Building Docker image..."
docker build \
  --build-arg BUILD_VERSION="$(git rev-parse --short HEAD)" \
  -t "$ECR_REPO:$IMAGE_TAG" \
  -t "$ECR_REPO:$(git rev-parse --short HEAD)" \
  backend/

log "Pushing image..."
docker push "$ECR_REPO:$IMAGE_TAG"
docker push "$ECR_REPO:$(git rev-parse --short HEAD)"

log "Triggering rolling deploy on ASG: $ASG_NAME"
REFRESH_ID=$(aws autoscaling start-instance-refresh \
  --auto-scaling-group-name "$ASG_NAME" \
  --strategy Rolling \
  --preferences '{"MinHealthyPercentage":50,"InstanceWarmup":60}' \
  --query 'InstanceRefreshId' --output text)

log "Waiting for instance refresh: $REFRESH_ID"
for i in {1..40}; do
  STATUS=$(aws autoscaling describe-instance-refreshes \
    --auto-scaling-group-name "$ASG_NAME" \
    --instance-refresh-ids "$REFRESH_ID" \
    --query 'InstanceRefreshes[0].Status' --output text)
  log "[$i/40] $STATUS"
  [ "$STATUS" = "Successful" ] && { log "Deploy complete!"; exit 0; }
  [[ "$STATUS" = "Failed" || "$STATUS" = "Cancelled" ]] && fail "Deploy $STATUS"
  sleep 15
done
fail "Deployment timed out"
