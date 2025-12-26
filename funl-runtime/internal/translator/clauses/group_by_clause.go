package clauses

import (
	"fmt"
	"strings"
	"funl/internal/query"
)

type GroupByClause struct{}

func (c GroupByClause) Build(q query.AQL) string {
	// Only add GROUP BY if:
	// - Aggregates exist AND
	// - (Either group_by or columns provided)
	if len(q.Aggregates) == 0 {
		return ""
	}

	// Auto-group by Columns if GroupBy is empty
	groupCols := q.GroupBy
	if len(groupCols) == 0 && len(q.Columns) > 0 {
		groupCols = q.Columns
	}

	if len(groupCols) == 0 {
		return ""
	}

	return fmt.Sprintf("GROUP BY %s", strings.Join(groupCols, ", "))
}
