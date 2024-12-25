package style

import (
	"strings"

	"github.com/gorilla/css/scanner"
)

// StyleEngine handles CSS parsing and application
type StyleEngine struct {
	rules map[string]map[string]string
}

// NewStyleEngine creates a new style engine
func NewStyleEngine() *StyleEngine {
	return &StyleEngine{
		rules: make(map[string]map[string]string),
	}
}

// ParseCSS parses a CSS string and returns a map of properties
func (e *StyleEngine) ParseCSS(css string) (map[string]string, error) {
	properties := make(map[string]string)
	s := scanner.New(css)

	var property string
	var value strings.Builder
	inValue := false

	for {
		token := s.Next()
		if token.Type == scanner.TokenEOF {
			break
		}

		switch token.Type {
		case scanner.TokenIdent:
			if !inValue {
				property = token.Value
			} else {
				value.WriteString(token.Value)
			}
		case scanner.TokenS:
			if inValue {
				value.WriteString(" ")
			}
		case scanner.TokenChar:
			if token.Value == ":" {
				inValue = true
			} else if token.Value == ";" {
				if property != "" {
					properties[property] = strings.TrimSpace(value.String())
				}
				property = ""
				value.Reset()
				inValue = false
			} else if inValue {
				value.WriteString(token.Value)
			}
		default:
			if inValue {
				value.WriteString(token.Value)
			}
		}
	}

	// Handle the last property if it doesn't end with a semicolon
	if property != "" && inValue {
		properties[property] = strings.TrimSpace(value.String())
	}

	return properties, nil
}

// ApplyStyles applies parsed styles to a component
func (e *StyleEngine) ApplyStyles(componentID string, styles map[string]string) {
	e.rules[componentID] = styles
}
