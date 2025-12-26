package clauses

import (
	"fmt"
	"strings"
	"funl/internal/query"
	"funl/internal/bind"
)

type HavingClause struct{}

func (c HavingClause) BuildWithParams(q query.AQL, binder *bind.ParamBinder) string {
	if len(q.Having) == 0 {
		return ""
	}

	conds := []string{}
	for _, h := range q.Having {
		placeholder := binder.Add(h.Value)
		switch strings.ToLower(h.Operator) {
		case "gt":
			conds = append(conds, fmt.Sprintf("%s > %s", h.Field, placeholder))
		case "lt":
			conds = append(conds, fmt.Sprintf("%s < %s", h.Field, placeholder))
		case "eq":
			conds = append(conds, fmt.Sprintf("%s = %s", h.Field, placeholder))
		case "gte":
			conds = append(conds, fmt.Sprintf("%s >= %s", h.Field, placeholder))
		case "lte":
			conds = append(conds, fmt.Sprintf("%s <= %s", h.Field, placeholder))
		}
	}

	return "HAVING " + strings.Join(conds, " AND ")
}
