package api

import (
    "encoding/json"
    "net/http"
    "time"

    "log/slog"

    "github.com/google/uuid"

    "funl/internal/query"
    "funl/internal/translator"
    "funl/internal/executor"
     "funl/internal/middleware"
)

type ExecuteRequest struct {
    AQL        query.AQL           `json:"aql"`
    Datasource executor.Datasource `json:"datasource"`
}

func ExecuteHandler(w http.ResponseWriter, r *http.Request) {
    start := time.Now()

    cid := middleware.GetCorrelationID(r.Context())
    logger := slog.Default().With("correlation_id", cid)

    logger.Info("execute request started")

    var req ExecuteRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        logger.Error("invalid JSON", "error", err)
        http.Error(w, "invalid JSON: "+err.Error(), http.StatusBadRequest)
        return
    }

    maskRules := normalizeMaskRules(req.AQL.MaskFields)

    tr, err := translator.New(req.Datasource.Engine, maskRules)
    if err != nil {
        logger.Error("translator init failed", "error", err)
        http.Error(w, "translator init failed: "+err.Error(), http.StatusBadRequest)
        return
    }

    translateStart := time.Now()
    result, err := tr.Translate(req.AQL)
    translateMs := time.Since(translateStart).Milliseconds()

    if err != nil {
        logger.Error("translation failed", "error", err)
        http.Error(w, "translation failed: "+err.Error(), http.StatusInternalServerError)
        return
    }

		logger.Info("translation complete", "duration_ms", translateMs)

    exec, err := executor.New(req.Datasource)
    if err != nil {
        logger.Error("executor init failed", "error", err)
        http.Error(w, "executor init failed: "+err.Error(), http.StatusInternalServerError)
        return
    }

    dbStart := time.Now()
    rows, err := exec.Execute(result.Query, result.Parameters)
    dbMs := time.Since(dbStart).Milliseconds()

    if err != nil {
        logger.Error("query failed", "error", err)
        http.Error(w, "query failed: "+err.Error(), http.StatusInternalServerError)
        return
    }

    totalMs := time.Since(start).Milliseconds()

    meta := map[string]any{
        "engine":          req.Datasource.Engine,
        "masked_fields":   maskRules,
        "masking_applied": len(maskRules) > 0,
        "duration_ms":     totalMs,
        "db_exec_ms":      dbMs,
        "row_count":       len(rows),
        "correlation_id":  cid,
        "request_id":      "exec_" + uuid.NewString(),
        "timestamp":       time.Now().UTC().Format(time.RFC3339),
        "query":           result.Query,
        "parameters":      result.Parameters,
    }

    response := map[string]any{
        "query": result.Query,
        "rows":  rows,
        "meta":  meta,
    }

    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(response)

    logger.Info("execute request completed",
        "duration_ms", totalMs,
        "row_count", len(rows),
    )
}

func normalizeMaskRules(m any) map[string]string {
	result := map[string]string{}

	switch v := m.(type) {

	case map[string]string:
			// already a proper map
			return v

	case []string:
			// list means everything is fully masked
			for _, field := range v {
					result[field] = "full"
			}

	case []any:
			for _, f := range v {
					if field, ok := f.(string); ok {
							result[field] = "full"
					}
			}
	}

	return result
}