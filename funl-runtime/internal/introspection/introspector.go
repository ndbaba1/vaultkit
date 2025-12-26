package introspection

import (
    "fmt"

    "funl/internal/executor"
)

type Introspector interface {
    Tables(ds executor.Datasource) ([]map[string]any, error)
    Columns(ds executor.Datasource, table string) ([]map[string]any, error)
}

func SelectIntrospector(engine string) (Introspector, error) {
    switch engine {
    case "postgres", "postgresql":
        return PostgresIntrospector{}, nil
    case "mysql":
        return MySQLIntrospector{}, nil
    case "snowflake":
        return SnowflakeIntrospector{}, nil
    default:
        return nil, fmt.Errorf("unsupported engine: %s", engine)
    }
}
