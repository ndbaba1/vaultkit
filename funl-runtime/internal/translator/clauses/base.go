package clauses

import "funl/internal/query"

type Clause interface {
	Build(q query.AQL) string
}
