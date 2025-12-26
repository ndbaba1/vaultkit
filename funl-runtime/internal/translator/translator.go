package translator

import "funl/internal/query"

// TranslationResult holds both the query and its parameter bindings.
type TranslationResult struct {
	Query      string
	Parameters []interface{}
}

type Translator interface {
	Translate(q query.AQL) (TranslationResult, error)
}
