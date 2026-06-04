package config

import (
	"os"
	"strings"
)

type Config struct {
	Port           string
	Env            string
	MongoURI       string
	RedisURL       string
	AllowedOrigins []string
}

func Load() *Config {
	origins := strings.Split(getEnv("ALLOWED_ORIGINS", "http://localhost:3000"), ",")
	return &Config{
		Port:           getEnv("APP_PORT", "8080"),
		Env:            getEnv("APP_ENV", "development"),
		MongoURI:       getEnv("MONGODB_URI", "mongodb://localhost:27017/starttech"),
		RedisURL:       getEnv("REDIS_URL", "redis://localhost:6379"),
		AllowedOrigins: origins,
	}
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
