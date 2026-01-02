package api

import (
    "encoding/json"
    "net/http"
    "time"

    "log/slog"

    "funl/internal/executor"
    "funl/internal/introspection"
    "funl/internal/middleware"
)

type IntrospectRequest struct {
    Datasource executor.Datasource `json:"datasource"`
    Kind       string              `json:"kind"`
    Table      string              `json:"table,omitempty"`
}

func IntrospectHandler(w http.ResponseWriter, r *http.Request) {
    start := time.Now()

    cid := middleware.GetCorrelationID(r.Context())
    logger := slog.Default().With("correlation_id", cid)

    logger.Info("introspection request started")

    if r.Method != http.MethodPost {
        http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
        return
    }

    // Parse request body
    var req IntrospectRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        logger.Error("invalid JSON", "error", err)
        http.Error(w, "invalid JSON: "+err.Error(), http.StatusBadRequest)
        return
    }

    // Extract role from JWT claims (already validated in router)
    role := middleware.GetJWTRole(r.Context())
    if role == "" {
        http.Error(w, "missing claims", http.StatusUnauthorized)
        return
    }

    if role != "schema_scanner" && role != "admin" {
        http.Error(w, "forbidden: insufficient role", http.StatusForbidden)
        return
    }

    // Select introspector
    insp, err := introspection.SelectIntrospector(req.Datasource.Engine)
    if err != nil {
        logger.Error("unsupported engine", "error", err)
        http.Error(w, "unsupported engine: "+err.Error(), http.StatusBadRequest)
        return
    }

    // Run introspection based on kind
    var rows []map[string]any

    switch req.Kind {
    case "tables":
        rows, err = insp.Tables(req.Datasource)

    case "columns":
        if req.Table == "" {
            http.Error(w, "missing table for columns", http.StatusBadRequest)
            return
        }
        rows, err = insp.Columns(req.Datasource, req.Table)

    case "schema":
        rows = []map[string]any{}
        tables, err := insp.Tables(req.Datasource)
        if err != nil {
            break
        }

        for _, t := range tables {
            tbl := t["table_name"].(string)
            cols, err := insp.Columns(req.Datasource, tbl)
            if err != nil {
                break
            }

            rows = append(rows, map[string]any{
                "table":   tbl,
                "columns": cols,
            })
        }

    default:
        http.Error(w, "unsupported kind: "+req.Kind, http.StatusBadRequest)
        return
    }

    if err != nil {
        logger.Error("introspection failed", "error", err)
        http.Error(w, "introspection failed: "+err.Error(), http.StatusInternalServerError)
        return
    }

    // Build response
    durationMs := time.Since(start).Milliseconds()

    resp := map[string]any{
        "rows": rows,
        "meta": map[string]any{
            "engine":         req.Datasource.Engine,
            "kind":           req.Kind,
            "duration_ms":    durationMs,
            "correlation_id": cid,
            "timestamp":      time.Now().UTC().Format(time.RFC3339),
        },
    }

    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(resp)

    logger.Info("introspection completed",
        "duration_ms", durationMs,
        "row_count", len(rows),
    )
}
