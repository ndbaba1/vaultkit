package clauses

import (
    "fmt"
    "strings"

    "funl/internal/query"
    "funl/internal/masking"
)

type SelectClause struct {
    Dialect   masking.MaskingDialect
    MaskRules map[string]string // columnName → maskType
}

func (c SelectClause) Build(q query.AQL) string {
    var selectParts []string

    // Regular columns
    for _, col := range q.Columns {
        selectParts = append(selectParts, c.maskOrRaw(col, q.SourceTable))
    }

    // Aggregates
    for _, agg := range q.Aggregates {
        expr := fmt.Sprintf("%s(%s)", strings.ToUpper(agg.Func), agg.Field)
        if agg.Alias != "" {
            expr += fmt.Sprintf(" AS %s", agg.Alias)
        }
        selectParts = append(selectParts, expr)
    }

    // No columns or aggregates → SELECT *
    if len(selectParts) == 0 {
        selectParts = append(selectParts, "*")
    }

    return fmt.Sprintf(
        "SELECT %s FROM %s",
        strings.Join(selectParts, ", "),
        q.SourceTable,
    )
}

// maskOrRaw returns either the masked or raw version of a field,
// depending solely on explicit MaskRules. No implicit masking.
func (c SelectClause) maskOrRaw(field, table string) string {
    full := fullyQualified(field, table)

    // Never mask aggregates (e.g. COUNT(id))
    if isAggregate(field) {
        return full
    }

    // Lookup mask rule (supports "table.col" or "col")
    maskType := c.MaskRules[field]
    if maskType == "" {
        maskType = c.MaskRules[alias(field)]
    }

    // No mask rule → return raw column
    if maskType == "" {
        return full
    }

    // Apply mask based on explicit rule
    switch strings.ToLower(maskType) {
    case "full":
        return c.Dialect.MaskFull(full)
    case "partial":
        return c.Dialect.MaskPartial(full)
    case "hash":
        return c.Dialect.MaskHash(full)
    default:
        return full
    }
}

// Utility helpers
func fullyQualified(field, table string) string {
    if strings.Contains(field, ".") {
        return field
    }
    return fmt.Sprintf("%s.%s", table, field)
}

func alias(f string) string {
    parts := strings.Split(f, ".")
    return parts[len(parts)-1]
}

func isAggregate(f string) bool {
    return strings.Contains(f, "(")
}
