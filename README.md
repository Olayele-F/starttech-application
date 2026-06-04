# starttech-application

Full-stack application for StartTech — React frontend + Golang backend, with GitHub Actions CI/CD pipelines deploying to AWS.

## Repository Structure

```
starttech-application/
├── .github/workflows/
│   ├── frontend-ci-cd.yml    # React → S3 + CloudFront
│   └── backend-ci-cd.yml     # Golang → ECR → EC2 ASG (rolling)
├── frontend/                 # React application (CRA)
│   ├── src/
│   │   ├── App.js
│   │   └── index.js
│   └── package.json
├── backend/                  # Golang API
│   ├── main.go
│   ├── config/config.go
│   ├── handlers/handlers.go
│   ├── middleware/middleware.go
│   ├── go.mod
│   └── Dockerfile
└── scripts/
    ├── deploy-frontend.sh
    ├── deploy-backend.sh
    ├── health-check.sh
    └── rollback.sh
```

## GitHub Secrets Required

### Frontend pipeline
| Secret                         | Description                        |
|--------------------------------|------------------------------------|
| `AWS_ACCESS_KEY_ID`            | IAM access key                     |
| `AWS_SECRET_ACCESS_KEY`        | IAM secret key                     |
| `S3_BUCKET_NAME`               | S3 bucket for frontend             |
| `CLOUDFRONT_DISTRIBUTION_ID`   | CloudFront distribution ID         |
| `CLOUDFRONT_DOMAIN`            | CloudFront domain (smoke test)     |
| `REACT_APP_API_URL`            | Backend ALB URL                    |

### Backend pipeline
| Secret                  | Description                          |
|-------------------------|--------------------------------------|
| `AWS_ACCESS_KEY_ID`     | IAM access key                       |
| `AWS_SECRET_ACCESS_KEY` | IAM secret key                       |
| `ECR_REPOSITORY`        | ECR repository name                  |
| `ASG_NAME`              | Auto Scaling Group name              |
| `LAUNCH_TEMPLATE_NAME`  | EC2 launch template name             |
| `ALB_DNS_NAME`          | ALB DNS for smoke test               |

## Local Development

### Backend
```bash
cd backend
export MONGODB_URI="mongodb://localhost:27017/starttech"
export REDIS_URL="redis://localhost:6379"
go run .
# API at http://localhost:8080
```

### Frontend
```bash
cd frontend
REACT_APP_API_URL=http://localhost:8080 npm start
# App at http://localhost:3000
```

## API Endpoints

| Method | Path               | Description        |
|--------|--------------------|--------------------|
| GET    | /health            | Health check       |
| GET    | /ready             | Readiness check    |
| GET    | /api/v1/items      | List all items     |
| POST   | /api/v1/items      | Create item        |
| GET    | /api/v1/items/{id} | Get item by ID     |

## CI/CD Flow

**Frontend:** `push to main` → install → test → audit → build → S3 sync → CloudFront invalidate → smoke test

**Backend:** `push to main` → vet → lint → test → govulncheck → Docker build → ECR push → Trivy scan → ASG instance refresh → health check → rollback on failure
