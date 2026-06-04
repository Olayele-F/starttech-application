#!/usr/bin/env bash
set -euo pipefail

ASG_NAME="${1:-${ASG_NAME:?ASG_NAME required}}"
AWS_REGION="${AWS_REGION:-us-east-1}"

log()  { echo "[$(date +%T)] $*"; }
fail() { echo "[ERROR] $*" >&2; exit 1; }

log "Cancelling any in-progress instance refresh on: $ASG_NAME"
REFRESH_ID=$(aws autoscaling describe-instance-refreshes \
  --auto-scaling-group-name "$ASG_NAME" \
  --query 'InstanceRefreshes[?Status==`InProgress`].InstanceRefreshId | [0]' \
  --output text 2>/dev/null || echo "None")

if [[ "$REFRESH_ID" != "None" && -n "$REFRESH_ID" ]]; then
  aws autoscaling cancel-instance-refresh \
    --auto-scaling-group-name "$ASG_NAME"
  log "Refresh $REFRESH_ID cancelled"
fi

# Roll back to previous launch template version
CURRENT_VERSION=$(aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names "$ASG_NAME" \
  --query 'AutoScalingGroups[0].LaunchTemplate.Version' \
  --output text)

log "Current launch template version: $CURRENT_VERSION"

if [[ "$CURRENT_VERSION" -gt 1 ]]; then
  PREV=$((CURRENT_VERSION - 1))
  log "Rolling back to launch template version $PREV..."
  aws autoscaling start-instance-refresh \
    --auto-scaling-group-name "$ASG_NAME" \
    --strategy Rolling \
    --desired-configuration "{\"LaunchTemplate\":{\"Version\":\"$PREV\"}}" \
    --preferences '{"MinHealthyPercentage":50,"InstanceWarmup":60}'
  log "Rollback initiated to version $PREV"
else
  log "Already at version 1, cannot roll back further"
fi
