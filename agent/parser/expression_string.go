package parser

import (
	"errors"
	"fmt"
	"strings"
)

// String

type stringExpression struct {
	value string
	err   error
	l     int
	p     int
}

func newStringExpression(value interface{}, line, position int) expression {
	result := &stringExpression{
		value: fmt.Sprintf("%v", value),
		l:     line,
		p:     position,
	}

	return result
}

func (s *stringExpression) evaluate(c *executionContext) (interface{}, error) {
	return s.value, s.err
}

type stringProperty func(g *stringExpression) expression

var stringProperties = map[string]stringProperty{
	"split": func(s *stringExpression) expression {
		return s.split()
	},
}

func (s *stringExpression) split() expression {
	return newCallableExpression(
		"split",
		func(c *executionContext, args map[string]interface{}) (expression, error) {
			split := strings.Split(s.value, args["separator"].(string))

			result := make([]interface{}, len(split))

			for index, value := range split {
				result[index] = value
			}

			return newArrayExpression(result, s.l, s.p), nil
		},
		map[string]callableArgument{
			"separator": callableArgumentString,
		},
		s.l,
		s.p,
	)
}

func (s *stringExpression) extract(c *executionContext, property string) (expression, error) {
	if f, ok := stringProperties[property]; ok {
		return f(s), nil
	}

	return nil, errors.New(fmt.Sprintf("%s does not contain a property with the key `%s`", s, property))
}

func (s *stringExpression) line() int {
	return s.l
}

func (s *stringExpression) position() int {
	return s.p
}

func (s *stringExpression) String() string {
	return fmt.Sprintf("String(%s)", s.value)
}
