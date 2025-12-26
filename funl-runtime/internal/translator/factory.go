package translator

import "fmt"

func New(engine string, maskRules map[string]string) (Translator, error) {
    switch engine {
    case "postgres", "postgresql":
        return NewPostgresTranslator(maskRules)
    default:
        return nil, fmt.Errorf("unsupported engine: %s", engine)
    }
}
