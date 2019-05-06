/*	Definition section */
%{
extern int yylineno;
extern int yylex();
extern char* yytext;   // Get current token from lex
extern char buf[256];  // Get current code line from lex

/* Symbol table function - you can add new function if needed. */
int lookup_symbol();
void create_symbol();
void insert_symbol();
void dump_symbol();

%}

/* Use variable or self-defined structure to represent
 * nonterminal and token type
 */
%union {
    int i_val;
    double f_val;
    char* string;
}

/* Token without return */
%token PRINT 
%token IF ELSE FOR WHILE
%token ID SEMICOLON
%token ADD SUB MUL DIV MOD INC DEC
%token MT LT MTE LTE EQ NE
%token ASGN ADDASGN SUBASGN MULASGN DIVASGN MODASGN
%token AND OR NOT
%token LB RB LCB RCB LSB RSB COMMA
%token VOID INT FLOAT STRING BOOL
%token TRUE FALSE
%token RET
%token QUOTA C_Comment C++_Comment

/* Token with return, which need to sepcify type */
%token <i_val> I_CONST
%token <f_val> F_CONST
%token <string> STR_CONST

/* Nonterminal with return, which need to sepcify type */
%type <f_val> stat

/* Yacc will start at this nonterminal */
%start program

/* Grammar section */
%%

program
    : program stat
    |
;

stat
    : declaration
    | compound_stat
    | expression_stat
    | print_func
;

declaration
    : type ID ASGN expression SEMICOLON
    | type ID SEMICOLON
;

/* actions can be taken when meet the token or rule */
type
    : INT { $$ = $1; }
    | FLOAT { $$ = $1; }
    | BOOL  { $$ = $1; }
    | STRING { $$ = $1; }
    | VOID { $$ = $1; }
;

compound_stat
    : if_stat
    | while_stat
;

if_stat
    : IF expression block
    | IF expression block ELSE block
    | IF expression block ELSE if_stat
;

block
    : LCB program RCB
;

while_stat
    : WHILE expression block
;

expression_stat
    : ID assign_op expression SEMICOLON
;

expression
    : comparison_expr { $$ = $1; }
;

comparison_expr
    : addition_expr { $$ = $1; }
    | comparison_expr cmp_op addition_expr {}
;

addition_expr
    : multiplication_expr { $$ = $1; }
    | addition_expr add_op multiplication_expr {}
;

multiplication_expr
    : postfix_expr { $$ = $1; }
    | multiplication_expr mul_op postfix_expr {}
;

postfix_expr
    : parenthesis { $$ = $1; }
    | parenthesis post_op {}
;

parenthesis
    : constant { $$ = $1; }
    | ID {}
    | TRUE
    | FALSE
    | LB expression RB { $$ = $2; }
;

cmp_op
    : MT
    | LT
    | MTE
    | LTE
    | EQ
    | NE
;

add_op
    : ADD
    | SUB
;

mul_op
    : MUL
    | DIV
    | MOD
;

post_op
    : INC
    | DEC
;

assign_op
    : ASGN
    | ADDASGN
    | SUBASGN
    | MULASGN
    | DIVASGN
    | MODASGN
;

constant
    : I_CONST {}
    | F_CONST {}
;

print_func
    : PRINT LB ID RB SEMICOLON
    | PRINT LB QUOTA STR_CONST QUOTA RB SEMICOLON
%%

/* C code section */
int main(int argc, char** argv)
{
    yylineno = 0;

    yyparse();
	printf("\nTotal lines: %d \n",yylineno);

    return 0;
}

void yyerror(char *s)
{
    printf("\n|-----------------------------------------------|\n");
    printf("| Error found in line %d: %s\n", yylineno, buf);
    printf("| %s", s);
    printf("\n|-----------------------------------------------|\n\n");
}

void create_symbol() {}
void insert_symbol() {}
int lookup_symbol() {}
void dump_symbol() {
    printf("\n%-10s%-10s%-12s%-10s%-10s%-10s\n\n",
           "Index", "Name", "Kind", "Type", "Scope", "Attribute");
}
