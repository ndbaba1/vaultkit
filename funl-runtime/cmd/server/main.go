package main

import (
	"log"
	"net/http"
	"os"

	"funl/internal/server"
	"funl/internal/auth"
)

func main() {
	addr := os.Getenv("FUNL_ADDR")
	if addr == "" {
		addr = ":8080"
	}

	log.Printf("🚀 Funl API running on %s\n", addr)

	pubKeyPath := os.Getenv("VKIT_PUBLIC_KEY")
	if pubKeyPath == "" {
		log.Fatalf("VKIT_PUBLIC_KEY is not set")
	}

	pubKey, err := os.ReadFile(pubKeyPath)
	if err != nil {
		log.Fatalf("failed to read VKIT_PUBLIC_KEY at %s: %v", pubKeyPath, err)
	}

	auth.InitAuth(pubKey)

	router := server.NewRouter()

	log.Fatal(
		http.ListenAndServe(addr, router),
	)
}
