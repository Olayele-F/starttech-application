#!/usr/bin/env bash
set -euo pipefail

ALB_DNS="${ALB_DNS_NAME:?ALB_DNS_NAME required}"
CF_DOMAIN="${CLOUDFRONT_DOMAIN:?CLOUDFRONT_DOMAIN required}"
MAX_RETRIES="${MAX_RETRIES:-5}"
SLEEP="${SLEEP_SECONDS:-10}"

log()  { echo "[$(date +%T)] $*"; }
pass() { echo "[PASS] $*"; }
fail() { echo "[FAIL] $*" >&2; exit 1; }

check() {
  local url="$1" label="$2"
  for i in $(seq 1 "$MAX_RETRIES"); do
    STATUS=$(curl -fsSL -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
    if [[ "$STATUS" =~ ^2 ]]; then
      pass "$label — HTTP $STATUS"
      return 0
    fi
    log "[$i/$MAX_RETRIES] $label HTTP $STATUS, retrying..."
    sleep "$SLEEP"
  done
  fail "$label failed after $MAX_RETRIES attempts (last: $STATUS)"
}

log "Running health checks..."
check "http://${ALB_DNS}/health"  "Backend /health"
check "http://${ALB_DNS}/ready"   "Backend /ready"
check "https://${CF_DOMAIN}"      "Frontend CloudFront"
log "All checks passed."
