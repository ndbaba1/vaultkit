package introspection

import (
    "funl/internal/executor"
)

type PostgresIntrospector struct{}

func (p PostgresIntrospector) Tables(ds executor.Datasource) ([]map[string]any, error) {
    exec, err := executor.New(ds)
    if err != nil {
        return nil, err
    }

    schema := "public"

    sql := `
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = $1
        ORDER BY table_name;
    `

    return exec.Execute(sql, []any{schema})
}

func (p PostgresIntrospector) Columns(ds executor.Datasource, table string) ([]map[string]any, error) {
    exec, err := executor.New(ds)
    if err != nil {
        return nil, err
    }

    schema := "public"

    sql := `
        SELECT column_name, data_type
        FROM information_schema.columns
        WHERE table_schema = $1
          AND table_name = $2
        ORDER BY ordinal_position;
    `

    return exec.Execute(sql, []any{schema, table})
}
