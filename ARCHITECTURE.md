# StartTech Application Architecture

## Overview
StartTech is a full-stack application consisting of a React frontend and a Golang backend API, deployed on AWS with automated CI/CD via GitHub Actions.

## Repository Structure
starttech-application/ ├── .github/workflows/ │ ├── frontend-ci-cd.yml # React build and S3 deployment │ └── backend-ci-cd.yml # Go build, Docker, EC2 deployment ├── frontend/ # React application │ ├── src/ │ │ ├── App.js │ │ └── tests/ │ ├── public/ │ └── package.json ├── backend/ # Golang API │ ├── config/ │ ├── handlers/ │ ├── middleware/ │ ├── Dockerfile │ └── main.go └── scripts/ ├── deploy-frontend.sh ├── deploy-backend.sh ├── health-check.sh └── rollback.sh
## Frontend (React) 
- Single-page application built with React 
- Uses relative URLs — API calls routed through CloudFront 
- Environment variables baked in at build time via REACT_APP_* secrets 
- Deployed to S3, served via CloudFront CDN 
### Frontend CI/CD Flow
Push to main (frontend/**) │ ▼ Build & Test ├── npm ci ├── Unit tests ├── Security audit └── npm run build │ ▼ Deploy ├── S3 sync (hashed assets — 1yr cache) ├── S3 sync (index.html — no cache) └── CloudFront invalidation
## Backend (Golang)
- REST API built in Go with standard net/http
- Structured JSON logging to CloudWatch
- Health endpoint: GET /health
- Readiness endpoint: GET /ready
- API endpoints: GET/POST /api/v1/items, GET /api/v1/items/{id}

### Middleware Chain
Request → RequestID → Logger → CORS → Recovery → Handler
### Backend CI/CD Flow
Push to main (backend/**) │ ▼ Test & Lint ├── go vet ├── golangci-lint ├── Unit tests (with Redis) └── govulncheck │ ▼ Docker Build & Push ├── Multi-stage build (golang:alpine → distroless) ├── Push to ECR (:latest, :sha-xxxxx) └── Trivy vulnerability scan │ ▼ Rolling Deploy ├── ASG instance refresh └── 50% minimum healthy during deploy
## API Endpoints 
| Method | Path | Description | 
|---|---|---| 
| GET | /health | Health check | 
| GET | /ready | Readiness check | 
| GET | /api/v1/items | List all items | 
| POST | /api/v1/items | Create item | 
| GET | /api/v1/items/{id} | Get item by ID | 
## Environment Variables 
### Backend 
| Variable | Description | Default | 
|---|---|---| 
| APP_PORT | Server port | 8080 | 
| APP_ENV | Environment name | development | 
| MONGODB_URI | MongoDB connection string | mongodb://localhost:27017/starttech | 
| REDIS_URL | Redis connection URL | redis://localhost:6379 | 
| ALLOWED_ORIGINS | CORS allowed origins (comma-separated) | http://localhost:3000 
| 
### Frontend 
| Variable | Description | 
|---|---| 
| REACT_APP_API_URL | Backend API base URL | 
| REACT_APP_ENV | Environment name | 

## Security 
- CORS middleware restricts API access to allowed origins only 
- Docker image uses distroless base (minimal attack surface) 
- Trivy scans image for CRITICAL/HIGH vulnerabilities before deploy 
- golangci-lint with security rules runs on every PR 
- No secrets committed to repository — all via GitHub Actions secrets 
