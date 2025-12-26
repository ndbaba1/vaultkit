package clauses

import (
	"fmt"
	"strings"
	"funl/internal/bind"
	"funl/internal/query"
)

type JoinClause struct{}

func (c JoinClause) BuildWithParams(q query.AQL, binder *bind.ParamBinder) string {
	if len(q.Joins) == 0 {
		return ""
	}

	var joins []string
	for _, j := range q.Joins {
		joinType := strings.ToUpper(strings.TrimSpace(j.Type))
		if joinType == "" {
			joinType = "INNER"
		}

		joins = append(joins,
			fmt.Sprintf("%s JOIN %s ON %s = %s", joinType, j.Table, j.LeftField, j.RightField))
	}

	return strings.Join(joins, " ")
}
