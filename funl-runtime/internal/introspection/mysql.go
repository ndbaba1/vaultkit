package introspection

import (
    "funl/internal/executor"
)

type MySQLIntrospector struct{}

func (m MySQLIntrospector) Tables(ds executor.Datasource) ([]map[string]any, error) {
    exec, err := executor.New(ds)
    if err != nil {
        return nil, err
    }

    sql := `
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = DATABASE()
        ORDER BY table_name;
    `

    return exec.Execute(sql, nil)
}

func (m MySQLIntrospector) Columns(ds executor.Datasource, table string) ([]map[string]any, error) {
    exec, err := executor.New(ds)
    if err != nil {
        return nil, err
    }

    sql := `
        SELECT column_name, data_type
        FROM information_schema.columns
        WHERE table_schema = DATABASE()
          AND table_name = ?
        ORDER BY ordinal_position;
    `

    return exec.Execute(sql, []any{table})
}
