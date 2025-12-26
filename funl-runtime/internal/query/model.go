package query

// Join represents a SQL JOIN clause
type Join struct {
	Type       string `json:"type,omitempty"`   // INNER, LEFT, RIGHT, FULL
	Table      string `json:"table"`            // table to join
	Alias      string `json:"alias,omitempty"`  // e.g. "o"
	LeftField  string `json:"left_field"`       // users.id
	RightField string `json:"right_field"`      // orders.user_id
}

// Aggregation represents SUM, AVG, COUNT, etc.
type Aggregation struct {
	Func  string `json:"func"`                // SUM
	Field string `json:"field"`               // orders.amount
	Alias string `json:"alias,omitempty"`     // total_amount
}

// Filter for WHERE or nested conditions
type Filter struct {
	Operator   string      `json:"operator"`
	Field      string      `json:"field,omitempty"`
	Value      interface{} `json:"value,omitempty"`
	Logic      string      `json:"logic,omitempty"`
	Conditions []Filter    `json:"conditions,omitempty"`
}

// OrderBy represents sorting
type OrderBy struct {
	Column    string `json:"column"`
	Direction string `json:"direction"` // ASC | DESC
}

// Having represents aggregate filters
type Having struct {
	Operator string      `json:"operator"`
	Field    string      `json:"field"`
	Value    interface{} `json:"value"`
}

// AQL represents the full Access Query Language request
type AQL struct {
	SourceTable string        `json:"source_table"`
	Columns     []string      `json:"columns,omitempty"`
	Joins       []Join        `json:"joins,omitempty"`
	Aggregates  []Aggregation `json:"aggregates,omitempty"`
	GroupBy     []string      `json:"group_by,omitempty"`
	Having      []Having      `json:"having,omitempty"`
	Filters     []Filter      `json:"filters,omitempty"`
	OrderBy     *OrderBy      `json:"order_by,omitempty"`
	Limit       int           `json:"limit,omitempty"`
	Offset      int           `json:"offset,omitempty"`
	MaskFields  any           `json:"mask_fields"`
}
