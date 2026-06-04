# ── Build ──────────────────────────────────────────────────────────────────────
FROM golang:1.22-alpine AS builder
ARG BUILD_VERSION=dev
ENV CGO_ENABLED=0 GOOS=linux GOARCH=amd64
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download && go mod verify
COPY . .
RUN go build -ldflags="-s -w -X main.Version=${BUILD_VERSION}" -o /server .

# ── Runtime ────────────────────────────────────────────────────────────────────
FROM gcr.io/distroless/static-debian12
COPY --from=builder /server /server
EXPOSE 8080
USER nonroot:nonroot
ENTRYPOINT ["/server"]
