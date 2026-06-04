package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/starttech/backend/config"
)

type healthResponse struct {
	Status    string    `json:"status"`
	Timestamp time.Time `json:"timestamp"`
	Version   string    `json:"version"`
}

func HealthCheck(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, healthResponse{
		Status:    "ok",
		Timestamp: time.Now().UTC(),
		Version:   "1.0.0",
	})
}

func ReadinessCheck(cfg *config.Config) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		writeJSON(w, http.StatusOK, map[string]string{
			"status": "ready",
			"env":    cfg.Env,
		})
	}
}

type Item struct {
	ID        string    `json:"id"`
	Name      string    `json:"name"`
	CreatedAt time.Time `json:"created_at"`
}

func ListItems(w http.ResponseWriter, r *http.Request) {
	items := []Item{
		{ID: "1", Name: "Sample Item 1", CreatedAt: time.Now().UTC()},
		{ID: "2", Name: "Sample Item 2", CreatedAt: time.Now().UTC()},
	}
	writeJSON(w, http.StatusOK, map[string]any{"items": items, "total": len(items)})
}

func GetItem(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	writeJSON(w, http.StatusOK, Item{
		ID: id, Name: "Sample Item", CreatedAt: time.Now().UTC(),
	})
}

func CreateItem(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Name string `json:"name"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Name == "" {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "name is required"})
		return
	}
	writeJSON(w, http.StatusCreated, Item{
		ID: "new-id", Name: body.Name, CreatedAt: time.Now().UTC(),
	})
}

func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}
