#!/usr/bin/env bash
set -euo pipefail

S3_BUCKET="${S3_BUCKET_NAME:?S3_BUCKET_NAME required}"
CF_DIST_ID="${CLOUDFRONT_DISTRIBUTION_ID:?CLOUDFRONT_DISTRIBUTION_ID required}"
BUILD_DIR="frontend/build"

log() { echo "[$(date +%T)] $*"; }

log "Building React app..."
cd frontend && npm ci && npm run build && cd ..

log "Syncing hashed assets (long cache)..."
aws s3 sync "$BUILD_DIR" "s3://$S3_BUCKET" \
  --delete \
  --cache-control "public,max-age=31536000,immutable" \
  --exclude "index.html" --exclude "*.json"

log "Syncing entry points (no cache)..."
aws s3 cp "$BUILD_DIR/index.html" "s3://$S3_BUCKET/index.html" \
  --cache-control "no-cache,no-store,must-revalidate"

log "Invalidating CloudFront..."
INV_ID=$(aws cloudfront create-invalidation \
  --distribution-id "$CF_DIST_ID" --paths "/*" \
  --query 'Invalidation.Id' --output text)
aws cloudfront wait invalidation-completed \
  --distribution-id "$CF_DIST_ID" --id "$INV_ID"

log "Frontend deployed."
