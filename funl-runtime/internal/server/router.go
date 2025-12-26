package server

import (
	"context"
	"log/slog"
	"net/http"
	"strings"
	"time"

	"funl/internal/api"
	"funl/internal/auth"
	"funl/internal/middleware"

	"github.com/google/uuid"
)

// ---------------------------------------------------------------
// Correlation ID middleware
// ---------------------------------------------------------------
func withCorrelationID(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		cid := r.Header.Get("X-Correlation-ID")
		if cid == "" {
			cid = uuid.New().String()
		}

		ctx := context.WithValue(r.Context(), middleware.CtxKeyCorrelationID, cid)
		w.Header().Set("X-Correlation-ID", cid)

		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

// ---------------------------------------------------------------
// Logging Middleware
// ---------------------------------------------------------------
func withLogging(next http.Handler) http.Handler {
	logger := slog.Default()

	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		cid := middleware.GetCorrelationID(r.Context())

		logger.Info("request started",
			slog.String("path", r.URL.Path),
			slog.String("method", r.Method),
			slog.String("correlation_id", cid),
		)

		next.ServeHTTP(w, r)

		logger.Info("request finished",
			slog.String("path", r.URL.Path),
			slog.String("method", r.Method),
			slog.String("correlation_id", cid),
			slog.Int64("duration_ms", time.Since(start).Milliseconds()),
		)
	})
}

// ---------------------------------------------------------------
// JWT Validation Middleware — injects claims into context
// ---------------------------------------------------------------
func withAuth(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {

		authHeader := r.Header.Get("Authorization")
		if authHeader == "" {
			http.Error(w, "missing Authorization", http.StatusUnauthorized)
			return
		}

		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			http.Error(w, "invalid Authorization format", http.StatusUnauthorized)
			return
		}

		claims, err := auth.ValidateToken(parts[1])
		if err != nil {
			http.Error(w, "invalid or expired token: "+err.Error(), http.StatusUnauthorized)
			return
		}

		// Inject claims into request context using middleware key
		ctx := context.WithValue(r.Context(), middleware.CtxKeyJWTClaims, claims)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

// ---------------------------------------------------------------
// Role Middleware — only allows schema_scanner or admin roles
// ---------------------------------------------------------------
func withIntrospectionRole(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {

		role := middleware.GetJWTRole(r.Context())
		if role == "" {
			http.Error(w, "missing claims", http.StatusUnauthorized)
			return
		}

		if role != "schema_scanner" && role != "admin" {
			http.Error(w, "forbidden: insufficient role", http.StatusForbidden)
			return
		}

		next.ServeHTTP(w, r)
	})
}

// ---------------------------------------------------------------
// Router
// ---------------------------------------------------------------
func NewRouter() http.Handler {
	mux := http.NewServeMux()

	// Health
	mux.HandleFunc("/health", api.HealthHandler)

	// AQL execution - any authenticated token may execute queries
	mux.Handle("/execute",
		withAuth(http.HandlerFunc(api.ExecuteHandler)),
	)

	// Introspection - ONLY schema_scanner or admin tokens permitted
	mux.Handle("/introspect",
		withAuth(withIntrospectionRole(http.HandlerFunc(api.IntrospectHandler))),
	)

	return withCorrelationID(withLogging(mux))
}
