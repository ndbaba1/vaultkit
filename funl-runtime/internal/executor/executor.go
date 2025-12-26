package executor

import (
	"fmt"
)

type Datasource struct {
    Engine   string `json:"engine"`
    Host     string `json:"host"`
    Port     int    `json:"port"`
    Database string `json:"database"`
    Username string `json:"username"`
    Password string `json:"password"`
}

type Executor interface {
    Execute(query string, params []any) ([]map[string]any, error)
}

func New(ds Datasource) (Executor, error) {
    switch ds.Engine {
    case "postgres":
        return NewPostgresExecutor(ds)
    default:
        return nil, fmt.Errorf("unsupported engine: %s", ds.Engine)
    }
}
