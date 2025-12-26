package masking

import "fmt"

type SnowflakeDialect struct{}

func (d SnowflakeDialect) MaskFull(field string) string {
    return fmt.Sprintf("'*****' AS %s", aliasFromField(field))
}

func (d SnowflakeDialect) MaskPartial(field string) string {
    return fmt.Sprintf("CONCAT(SUBSTR(%s, 1, 3), '****') AS %s", field, aliasFromField(field))
}

func (d SnowflakeDialect) MaskHash(field string) string {
    return fmt.Sprintf("SHA2(%s, 256) AS %s", field, aliasFromField(field))
}
