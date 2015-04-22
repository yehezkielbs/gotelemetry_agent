%{

	package parser

	type parseArgument struct {
		key string
		value expression
	}
	
%}

%union {
	cmd command
	ex expression
	exl map[string]expression
	exi parseArgument
	t token
}

%type <cmd> command, set_property, assign_to_var
%type <ex> expr, function_call, callable_expr, property
%type <exl> expr_list
%type <exi> expr_item
%token <t> T_STRING T_NUMBER T_IDENTIFIER T_VARIABLE
%token <t> T_PLUS T_MINUS T_MULTIPLY T_DIVIDE
%token <t> T_COMMA T_DOT T_COLON
%token <t> T_OPEN_PARENS T_CLOSE_PARENS T_OPEN_BRACKET T_CLOSE_BRACKET 

%left T_FUNCTION_CALL
%left T_PLUS T_MINUS
%left T_MULTIPLY T_DIVIDE
%left T_UMINUS T_UPLUS
%left T_DOT

%%

commands				: /* empty */
								| commands command

command					:
								set_property
								|
								assign_to_var
								;

set_property    :
								T_IDENTIFIER T_COLON expr
									{
										parserlex.(*aslLexer).AddCommand(newOutputCommand($1, $3))
									}
								;

assign_to_var		:
								T_VARIABLE T_COLON expr
									{
										parserlex.(*aslLexer).AddCommand(newAssignCommand($1, $3))
									}
								;

expr						: T_OPEN_PARENS expr T_CLOSE_PARENS
										{ $$ = $2 }
								|	expr T_PLUS expr
										{ $$ = newArithmeticExpression($1, $3, $2, $1.line(), $1.position()) }
								|	expr T_MINUS expr
										{ $$ = newArithmeticExpression($1, $3, $2, $1.line(), $1.position()) }
								|	expr T_MULTIPLY expr
										{ $$ = newArithmeticExpression($1, $3, $2, $1.line(), $1.position()) }
								|	expr T_DIVIDE expr
										{ $$ = newArithmeticExpression($1, $3, $2, $1.line(), $1.position()) }
								|	T_MINUS expr 			%prec T_UMINUS
										{ $$ = newArithmeticExpression(numericExpressionZero, $2, $1, $1.line, $1.start) }
								|	T_PLUS expr 			%prec T_UPLUS
										{ $$ = newArithmeticExpression(numericExpressionZero, $2, $1, $1.line, $1.start) }
								| T_NUMBER
										{ $$ = newNumericExpression($1.source, $1.line, $1.start) }
								| T_STRING
										{ $$ = newStringExpression($1.source, $1.line, $1.start) }
								| T_VARIABLE
										{ $$ = newVariableExpression($1.source, $1.line, $1.start) }
								| function_call
										{ $$ = $1 }
								| property
										{ $$ = $1 }
								; 

function_call 	: callable_expr T_OPEN_PARENS expr_list T_CLOSE_PARENS		%prec T_FUNCTION_CALL
										{ $$ = newFunctionCallExpression($1, $3, $1.line(), $1.position()) }
								;

callable_expr		: T_IDENTIFIER
										{ $$ = newPropertyExpression(newGlobalExpression($1.line, $1.start), $1.source, $1.line, $1.start) }
								|
									property
										{ $$ = $1 }
								;

property 				: expr T_DOT T_IDENTIFIER
										{ $$ = newPropertyExpression($1, $3.source, $1.line(), $1.position()) }
								;

expr_list				: expr_list T_COMMA expr_item
										{ $$[$3.key] = $3.value }
								| expr_item
										{ $$ = map[string]expression{$1.key: $1.value }}
								| /* empty */
										{ $$ = map[string]expression{} }
								;

expr_item				: T_IDENTIFIER T_COLON expr
										{ $$ = parseArgument{$1.source, $3} }
								;


