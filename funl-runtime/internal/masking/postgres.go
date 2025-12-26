package masking

import (
    "fmt"
)

type PostgresDialect struct{}

func (d PostgresDialect) MaskFull(field string) string {
    return fmt.Sprintf("'*****' AS %s", aliasFromField(field))
}

func (d PostgresDialect) MaskPartial(field string) string {
    return fmt.Sprintf("CONCAT(LEFT(%s, 3), '****') AS %s", field, aliasFromField(field))
}

func (d PostgresDialect) MaskHash(field string) string {
    return fmt.Sprintf("ENCODE(DIGEST(%s::text, 'sha256'), 'hex') AS %s", field, aliasFromField(field))
}
