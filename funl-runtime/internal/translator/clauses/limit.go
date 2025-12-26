package clauses

import (
	"fmt"
	"funl/internal/bind"
	"funl/internal/query"
)

type LimitClause struct{}

func (c LimitClause) BuildWithParams(q query.AQL, binder *bind.ParamBinder) string {
	sql := ""

	if q.Limit > 0 {
		sql += fmt.Sprintf("LIMIT %s ", binder.Add(q.Limit))
	}
	if q.Offset > 0 {
		sql += fmt.Sprintf("OFFSET %s ", binder.Add(q.Offset))
	}

	return sql
}
