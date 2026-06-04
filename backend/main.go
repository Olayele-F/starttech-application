package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/starttech/backend/config"
	"github.com/starttech/backend/handlers"
	"github.com/starttech/backend/middleware"
)

func main() {
	cfg := config.Load()

	mux := http.NewServeMux()

	// Health (no auth)
	mux.HandleFunc("GET /health", handlers.HealthCheck)
	mux.HandleFunc("GET /ready",  handlers.ReadinessCheck(cfg))

	// API v1
	mux.HandleFunc("GET /api/v1/items",      handlers.ListItems)
	mux.HandleFunc("POST /api/v1/items",     handlers.CreateItem)
	mux.HandleFunc("GET /api/v1/items/{id}", handlers.GetItem)

	handler := middleware.Chain(
		mux,
		middleware.RequestID,
		middleware.Logger,
		middleware.CORS(cfg.AllowedOrigins),
		middleware.Recovery,
	)

	srv := &http.Server{
		Addr:         fmt.Sprintf(":%s", cfg.Port),
		Handler:      handler,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	stop := make(chan os.Signal, 1)
	signal.Notify(stop, os.Interrupt, syscall.SIGTERM)

	go func() {
		log.Printf(`{"level":"INFO","msg":"server starting","port":"%s","env":"%s"}`,
			cfg.Port, cfg.Env)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("server error: %v", err)
		}
	}()

	<-stop
	log.Println(`{"level":"INFO","msg":"shutting down"}`)
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()
	if err := srv.Shutdown(ctx); err != nil {
		log.Fatalf("forced shutdown: %v", err)
	}
}

