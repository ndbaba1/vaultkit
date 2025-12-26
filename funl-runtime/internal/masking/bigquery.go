package masking

import "fmt"

type BigQueryDialect struct{}

func (d BigQueryDialect) MaskFull(field string) string {
    return fmt.Sprintf("'*****' AS %s", aliasFromField(field))
}

func (d BigQueryDialect) MaskPartial(field string) string {
    return fmt.Sprintf("CONCAT(SUBSTR(%s, 1, 3), '****') AS %s", field, aliasFromField(field))
}

func (d BigQueryDialect) MaskHash(field string) string {
    return fmt.Sprintf("TO_HEX(SHA256(%s)) AS %s", field, aliasFromField(field))
}
