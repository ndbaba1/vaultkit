package masking

import (
    "fmt"
    "strings"
)

type MaskingDialect interface {
    MaskFull(field string) string
    MaskPartial(field string) string
    MaskHash(field string) string
}

func NewDialect(engine string) (MaskingDialect, error) {
    switch strings.ToLower(engine) {
    case "postgres", "postgresql":
        return PostgresDialect{}, nil
    default:
        return nil, fmt.Errorf("unsupported masking dialect: %s", engine)
    }
}

func aliasFromField(f string) string {
    parts := strings.Split(f, ".")
    return parts[len(parts)-1]
}
