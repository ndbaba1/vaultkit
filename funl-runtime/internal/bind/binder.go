package bind

import "fmt"

type ParamBinder struct {
	params []interface{}
}

func New() *ParamBinder {
	return &ParamBinder{params: []interface{}{}}
}

func (b *ParamBinder) Add(value interface{}) string {
	b.params = append(b.params, value)
	return fmt.Sprintf("$%d", len(b.params))
}

func (b *ParamBinder) Params() []interface{} {
	return b.params
}
