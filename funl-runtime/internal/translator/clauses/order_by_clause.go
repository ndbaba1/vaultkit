package clauses

import (
	"fmt"
	"funl/internal/query"
)

type OrderByClause struct{}

func (c OrderByClause) Build(q query.AQL) string {
	if q.OrderBy == nil || q.OrderBy.Column == "" {
		return ""
	}

	dir := q.OrderBy.Direction
	if dir == "" {
		dir = "ASC"
	}

	return fmt.Sprintf("ORDER BY %s %s", q.OrderBy.Column, dir)
}
