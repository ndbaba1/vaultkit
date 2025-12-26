package translator

import (
    "fmt"
    "strings"
)

// Normalizes []string or map[string]string → map[field]maskType
func NormalizeMaskFields(raw any) map[string]string {
    result := map[string]string{}

    switch v := raw.(type) {

    // mask_fields: ["email", "ssn"]
    case []any:
        for _, item := range v {
            result[fmt.Sprint(item)] = "full"
        }

    // mask_fields: { "email": "hash", "ssn": "partial" }
    case map[string]any:
        for k, vv := range v {
            result[k] = fmt.Sprint(vv)
        }

    case map[string]string:
        return v

    default:
        return result
    }

    return result
}

// Apply dialect-appropriate SQL for a given mask_type
func ApplyMaskSQL(fullName, alias, maskType string) string {
    switch maskType {
    case "full":
        return fmt.Sprintf("'*****' AS %s", alias)

    case "hash":
        // PostgreSQL SHA256 hashing
        return fmt.Sprintf(
            "ENCODE(DIGEST(%s::text, 'sha256'), 'hex') AS %s",
            fullName, alias,
        )

    case "partial":
        // Show first 3 chars only
        return fmt.Sprintf(
            "CONCAT(LEFT(%s::text, 3), '****') AS %s",
            fullName, alias,
        )

    default:
        // default to full mask
        return fmt.Sprintf("'*****' AS %s", alias)
    }
}

// Extract alias from "table.field"
func AliasFromField(f string) string {
    parts := strings.Split(f, ".")
    return parts[len(parts)-1]
}

// Build "table.field" safely
func Qualified(table, field string) string {
    if strings.Contains(field, ".") {
        return field
    }
    return fmt.Sprintf("%s.%s", table, field)
}
