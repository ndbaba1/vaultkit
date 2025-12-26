package masking

import "fmt"

type MySQLDialect struct{}

func (d MySQLDialect) MaskFull(field string) string {
    return fmt.Sprintf("'*****' AS %s", aliasFromField(field))
}

func (d MySQLDialect) MaskPartial(field string) string {
    return fmt.Sprintf("CONCAT(LEFT(%s, 3), '****') AS %s", field, aliasFromField(field))
}

func (d MySQLDialect) MaskHash(field string) string {
    return fmt.Sprintf("SHA2(%s, 256) AS %s", field, aliasFromField(field))
}
