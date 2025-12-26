package executor

import (
	"context"
	"database/sql"
	"fmt"
	"time"

	_ "github.com/lib/pq"
)

type PostgresExecutor struct {
	db *sql.DB
}

func NewPostgresExecutor(ds Datasource) (*PostgresExecutor, error) {
	connStr := fmt.Sprintf(
		"host=%s port=%d user=%s password=%s dbname=%s sslmode=require",
		ds.Host,
		ds.Port,
		ds.Username,
		ds.Password,
		ds.Database,
	)

	db, err := sql.Open("postgres", connStr)
	if err != nil {
		return nil, fmt.Errorf("postgres open error: %w", err)
	}

	// Validate DSN by pinging
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	if err := db.PingContext(ctx); err != nil {
		return nil, fmt.Errorf("postgres connection failed: %w", err)
	}

	return &PostgresExecutor{db: db}, nil
}

// normalize converts DB-returned values into JSON-friendly types.
// Crucially: []byte → string (fixes Base64 bug)
func normalize(v any) any {
	switch val := v.(type) {

	case nil:
		return nil

	case []byte:
		return string(val)

	case time.Time:
		return val.UTC().Format(time.RFC3339)

	default:
		return val
	}
}

func (p *PostgresExecutor) Execute(query string, params []any) ([]map[string]any, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	rows, err := p.db.QueryContext(ctx, query, params...)
	if err != nil {
		return nil, fmt.Errorf("postgres query failed: %w", err)
	}
	defer rows.Close()

	cols, err := rows.Columns()
	if err != nil {
		return nil, fmt.Errorf("failed to read columns: %w", err)
	}

	results := []map[string]any{}

	for rows.Next() {
		raw := make([]any, len(cols))
		dest := make([]any, len(raw))

		// Prepare scan targets
		for i := range raw {
			dest[i] = &raw[i]
		}

		if err := rows.Scan(dest...); err != nil {
			return nil, fmt.Errorf("scan failed: %w", err)
		}

		row := make(map[string]any, len(cols))
		for i, col := range cols {
			row[col] = normalize(raw[i])
		}

		results = append(results, row)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("rows iteration failed: %w", err)
	}

	return results, nil
}
