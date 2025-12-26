package translator

import (
	"strings"

	"funl/internal/bind"
	"funl/internal/query"
	"funl/internal/masking"
	"funl/internal/translator/clauses"
)

type PostgresTranslator struct {
	Dialect   masking.MaskingDialect
	MaskRules map[string]string
}

func NewPostgresTranslator(maskRules map[string]string) (*PostgresTranslator, error) {
	dialect, err := masking.NewDialect("postgres")
	if err != nil {
		return nil, err
	}
	return &PostgresTranslator{
		Dialect:   dialect,
		MaskRules: maskRules,
	}, nil
}

func (t *PostgresTranslator) Translate(q query.AQL) (TranslationResult, error) {
	binder := bind.New()
	var parts []string

	selectClause := clauses.SelectClause{
		Dialect:   t.Dialect,
		MaskRules: t.MaskRules,
	}

	whereClause := clauses.WhereClause{
		Dialect:   t.Dialect,
		MaskRules: t.MaskRules,
	}

	havingClause := clauses.HavingClause{}
	joinClause := clauses.JoinClause{}
	groupByClause := clauses.GroupByClause{}
	orderByClause := clauses.OrderByClause{}
	limitClause := clauses.LimitClause{}

	clausesList := []string{
		selectClause.Build(q),
		joinClause.BuildWithParams(q, binder),
		whereClause.BuildWithParams(q, binder),
		groupByClause.Build(q),
		havingClause.BuildWithParams(q, binder),
		orderByClause.Build(q),
		limitClause.BuildWithParams(q, binder),
	}

	for _, c := range clausesList {
		if strings.TrimSpace(c) != "" {
			parts = append(parts, strings.TrimSpace(c))
		}
	}

	sql := strings.Join(parts, " ")

	return TranslationResult{
		Query:      sql,
		Parameters: binder.Params(),
	}, nil
}
