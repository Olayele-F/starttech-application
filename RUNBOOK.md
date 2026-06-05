# StartTech Application Runbook

## Quick Reference

| Resource | Value |
|---|---|
| Frontend URL | https://d1dfapj85ua87h.cloudfront.net |
| Health Check | https://d1dfapj85ua87h.cloudfront.net/health |
| API Base | https://d1dfapj85ua87h.cloudfront.net/api/v1 |
| Backend Logs | /starttech/production/backend |

## Local Development

### Frontend
```bash
cd frontend
npm install
npm start        # runs on http://localhost:3000
npm test         # run tests
npm run build    # production build
```

### Backend
```bash
cd backend
go mod download
go run .         # runs on :8080
go test ./...    # run tests
```

### Required local environment variables for backend
```bash
export APP_PORT=8080
export MONGODB_URI=mongodb://localhost:27017/starttech
export REDIS_URL=redis://localhost:6379
export ALLOWED_ORIGINS=http://localhost:3000
```

## Deployments

### Deploy Frontend
1. Push changes to main branch inside frontend/ directory
2. GitHub Actions triggers frontend-ci-cd.yml automatically
3. Monitor at: https://github.com/Olayele-F/starttech-application/actions

### Deploy Backend
1. Push changes to main branch inside backend/ directory
2. GitHub Actions triggers backend-ci-cd.yml automatically
3. Monitor at: https://github.com/Olayele-F/starttech-application/actions

### Manual Frontend Deploy
```bash
bash scripts/deploy-frontend.sh
```

### Manual Backend Deploy
```bash
bash scripts/deploy-backend.sh
```

## Troubleshooting

### Error: Failed to fetch on frontend
1. Check CloudFront is routing /api/* to ALB correctly
2. Verify ALLOWED_ORIGINS includes CloudFront domain on backend
3. Check backend health: curl https://d1dfapj85ua87h.cloudfront.net/health
4. View backend logs:
```bash
aws logs tail /starttech/production/backend --follow
```

### Backend returns 502 Bad Gateway
1. Check Docker container is running on EC2 instance
2. Check ALB target group health
3. Check backend logs for startup errors
4. Verify ECR image was pulled successfully

### Frontend shows old version after deploy
CloudFront cache may not be invalidated yet. Manually invalidate:
```bash
aws cloudfront create-invalidation \
  --distribution-id EAI2L5RI1C2SM \
  --paths "/*"
```

### Backend pipeline fails at Test & Lint
1. Run locally: go vet ./... and check for errors
2. Run: golangci-lint run
3. Check go.sum is up to date: go mod tidy

### Backend pipeline fails at Docker Build
1. Check Dockerfile syntax
2. Verify ECR repository exists
3. Check AWS credentials in GitHub secrets

### Backend pipeline fails at Deploy
1. Check ASG instance refresh status in AWS console
2. Verify new instance passes ALB health check
3. Use rollback script if needed:
```bash
bash scripts/rollback.sh starttech-production-asg
```

## Health Checks

### Check frontend is live
```bash
curl -I https://d1dfapj85ua87h.cloudfront.net
```

### Check backend API
```bash
curl https://d1dfapj85ua87h.cloudfront.net/health
```

### Check backend readiness
```bash
curl https://d1dfapj85ua87h.cloudfront.net/ready
```

## Rollback

### Frontend Rollback
Re-run a previous successful GitHub Actions workflow run from the Actions tab.

### Backend Rollback
```bash
bash scripts/rollback.sh starttech-production-asg
```

Or manually via AWS CLI:
```bash
aws autoscaling start-instance-refresh \
  --auto-scaling-group-name starttech-production-asg \
  --strategy Rolling \
  --desired-configuration '{"LaunchTemplate":{"Version":"<previous_version>"}}'
```

## GitHub Actions Secrets Required

| Secret | Description |
|---|---|
| AWS_ACCESS_KEY_ID | AWS access key for deployments |
| AWS_SECRET_ACCESS_KEY | AWS secret key for deployments |
| ECR_REPOSITORY | ECR repository name |
| ASG_NAME | Auto Scaling Group name |
| ALB_DNS_NAME | ALB DNS for health checks |
| S3_BUCKET_NAME | Frontend S3 bucket name |
| CLOUDFRONT_DISTRIBUTION_ID | CloudFront distribution ID |
| CLOUDFRONT_DOMAIN | CloudFront domain name |
| MONGODB_URI | MongoDB Atlas URI |
| REACT_APP_API_URL | Backend API URL (leave empty to use relative URLs) |
