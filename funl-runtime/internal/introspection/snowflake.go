package introspection

import (
    "fmt"

    "funl/internal/executor"
)

type SnowflakeIntrospector struct{}

func (s SnowflakeIntrospector) Tables(ds executor.Datasource) ([]map[string]any, error) {
    exec, err := executor.New(ds)
    if err != nil {
        return nil, err
    }

    schema := "PUBLIC"

    sql := fmt.Sprintf("SHOW TABLES IN SCHEMA %s", schema)

    return exec.Execute(sql, nil)
}

func (s SnowflakeIntrospector) Columns(ds executor.Datasource, table string) ([]map[string]any, error) {
    exec, err := executor.New(ds)
    if err != nil {
        return nil, err
    }

    schema := "PUBLIC"

    sql := fmt.Sprintf("SHOW COLUMNS IN TABLE %s.%s", schema, table)

    return exec.Execute(sql, nil)
}
