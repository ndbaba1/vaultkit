package clauses

import (
	"fmt"
	"strings"

	"funl/internal/bind"
	"funl/internal/masking"
	"funl/internal/query"
)

type WhereClause struct {
	Dialect   masking.MaskingDialect
	MaskRules map[string]string // field → maskType
}

func (c WhereClause) BuildWithParams(q query.AQL, binder *bind.ParamBinder) string {
	if len(q.Filters) == 0 {
		return ""
	}

	var parts []string
	for _, f := range q.Filters {
		expr := c.renderFilter(f, binder, q.SourceTable)
		if strings.TrimSpace(expr) != "" {
			parts = append(parts, expr)
		}
	}

	if len(parts) == 0 {
		return ""
	}

	return "WHERE " + strings.Join(parts, " AND ")
}

// ---------------- FILTER RENDERING ---------------- //

func (c WhereClause) renderFilter(f query.Filter, binder *bind.ParamBinder, table string) string {
	// Group node (nested conditions)
	if len(f.Conditions) > 0 {
		joiner := strings.ToUpper(strings.TrimSpace(f.Logic))
		if joiner != "OR" {
			joiner = "AND"
		}

		var sub []string
		for _, child := range f.Conditions {
			part := c.renderFilter(child, binder, table)
			if strings.TrimSpace(part) != "" {
				sub = append(sub, part)
			}
		}

		if len(sub) == 0 {
			return ""
		}

		return "(" + strings.Join(sub, " "+joiner+" ") + ")"
	}

	// Leaf node
	field := fullyQualified(f.Field, table)
	maskType := c.detectMaskType(f.Field)

	// Hash masking is the ONLY allowed masking in WHERE
	if maskType == "hash" {
		field = c.Dialect.MaskHash(field)
	}

	// All other masking types (full/partial) CANNOT be applied in WHERE
	// We simply use raw field.

	op := strings.ToLower(strings.TrimSpace(f.Operator))

	switch op {
	case "eq", "=":
		return fmt.Sprintf("%s = %s", field, binder.Add(f.Value))

	case "neq", "!=":
		return fmt.Sprintf("%s != %s", field, binder.Add(f.Value))

	case "gt", ">":
		return fmt.Sprintf("%s > %s", field, binder.Add(f.Value))

	case "lt", "<":
		return fmt.Sprintf("%s < %s", field, binder.Add(f.Value))

	case "gte", ">=":
		return fmt.Sprintf("%s >= %s", field, binder.Add(f.Value))

	case "lte", "<=":
		return fmt.Sprintf("%s <= %s", field, binder.Add(f.Value))

	case "like":
		return fmt.Sprintf("%s LIKE %s", field, binder.Add("%"+fmt.Sprint(f.Value)+"%"))

	case "in":
		list, ok := f.Value.([]any)
		if !ok || len(list) == 0 {
			return ""
		}
		placeholders := make([]string, 0, len(list))
		for _, v := range list {
			placeholders = append(placeholders, binder.Add(v))
		}
		return fmt.Sprintf("%s IN (%s)", field, strings.Join(placeholders, ", "))

	case "is_null":
		return fmt.Sprintf("%s IS NULL", field)

	case "is_not_null":
		return fmt.Sprintf("%s IS NOT NULL", field)

	default:
		// Safe fallback
		return fmt.Sprintf("%s = %s", field, binder.Add(f.Value))
	}
}

func (c WhereClause) detectMaskType(field string) string {
	// Check fully qualified
	if t, ok := c.MaskRules[field]; ok {
		return t
	}

	// Check non-qualified (most common)
	short := alias(field)
	return c.MaskRules[short]
}
