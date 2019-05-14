/*	Definition section */
%{
#include "compiler.h" 
#include "stdio.h"

typedef struct Entry Entry;
struct Entry {
    int index;
    char *name;
    char *kind;
    char *type;
    int scope;
    char *attribute;
    Entry *next;
};
typedef struct Header Header;
struct Header {
    int depth;
    Entry *root;
    Entry *tail;
    Header *previous;
};
Header *header_root = NULL;
Header *cur_header = NULL;

extern int yylineno;
extern int yylex();
extern char* yytext;   // Get current token from lex
extern char buf[256];  // Get current code line from lex
extern int flag;
extern char msg[100];

int depth = 0;
int entry_num[100] = {0};

/* Symbol table function - you can add new function if needed. */
int lookup_symbol(Header *header, char *id_name);
void create_symbol();
void insert_symbol(Header *header, char *id_name, char* type, char* kind, char* attribute);
void dump_symbol();
%}

/* Use variable or self-defined structure to represent
 * nonterminal and token type
 */
%union {
    struct Value value;
    char* type;
}

/* Token without return */
%token PRINT 
%token IF ELSE FOR WHILE
%token SEMICOLON
%token ADD SUB MUL DIV MOD INC DEC
%token MT LT MTE LTE EQ NE
%token ASGN ADDASGN SUBASGN MULASGN DIVASGN MODASGN
%token AND OR NOT
%token LB RB LCB RCB LSB RSB COMMA
%token RET
%token QUOTA
/* Token with return, which need to sepcify type */
%token <type> VOID INT FLOAT STRING BOOL
%token <value> ID I_CONST F_CONST STR_CONST
%token <value> TRUE FALSE
/* Nonterminal with return, which need to sepcify type */
%type <type> type
%type <value> expression comparison_expr addition_expr
%type <value> multiplication_expr postfix_expr parenthesis
%type <value> constant

/* Yacc will start at this nonterminal */
%start program
/* Grammar section */
%%
program
    : program stat
    | error
    | 
;
stat
    : declaration
    | compound_stat
    | expression_stat
    | print_func
    | func_definition
    | func
;
declaration
    : type ID ASGN expression SEMICOLON {
            insert_symbol(cur_header, $2.id_name, $1, "variable", "");
        }
    | type ID SEMICOLON {
            insert_symbol(cur_header, $2.id_name, $1, "variable", "");
        }
;
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
    : expression SEMICOLON
    | ID assign_op expression SEMICOLON
;
expression
    : comparison_expr { $$ = $1; }
;
comparison_expr
    : addition_expr { $$ = $1; }
    | comparison_expr cmp_op addition_expr
;
addition_expr
    : multiplication_expr { $$ = $1; }
    | addition_expr add_op multiplication_expr
;
multiplication_expr
    : postfix_expr { $$ = $1; }
    | multiplication_expr mul_op postfix_expr
;
postfix_expr
    : parenthesis { $$ = $1; }
    | parenthesis post_op
;
parenthesis
    : constant { $$ = $1; }
    | ID { $$ = $1; }
    | TRUE { $$ = $1; }
    | FALSE { $$ = $1; }
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
    : I_CONST { $$ = $1; }
    | F_CONST { $$ = $1; }
    | QUOTA STR_CONST QUOTA { $$ = $2; }
;
print_func
    : PRINT LB ID RB SEMICOLON
    | PRINT LB QUOTA STR_CONST QUOTA RB SEMICOLON
;
func_definition
    : type ID LB type_arguments RB func_block
;
type_arguments
    : type_arguments COMMA arg
    | arg
    |
;
arg
    : type ID
;
func_block
    : LCB program RCB
    | LCB program RET expression SEMICOLON RCB
;
func
    : ID LB arguments RB SEMICOLON
;
arguments
    : arguments COMMA ID
    | ID
;
%%

/* C code section */
int main(int argc, char** argv)
{
    yylineno = 0;
    yyparse();
	printf("\nTotal lines: %d \n",yylineno);

    dump_symbol();
    return 0;
}

void yyerror(char *s)
{
    if((strcmp(s, "syntax error") == 0) && flag == 0) {
        flag = -1;
    } 
    else {
        printf("%s\n", buf);
        printf("\n|-----------------------------------------------|\n");
        printf("| Error found in line %d: %s\n", yylineno, buf);
        printf("| %s", s);
        printf("\n|-----------------------------------------------|\n\n");
    }
}

void create_symbol() {
    Header *p = malloc(sizeof(Header));
    p->depth = depth++;
    p->root = malloc(sizeof(Entry));
    p->root->next = NULL;
    p->tail = p->root;
    printf("create a table: %d\n", p->depth);
    if (cur_header == NULL) {
        p->previous = NULL;
        cur_header = p;
        header_root = cur_header;
    }
    else {
        p->previous = cur_header;
        cur_header = p;
    }
}
void insert_symbol(Header *header, char* id_name, char* type, char* kind, char* attribute) {
    if (cur_header == NULL) {
        create_symbol();
        header = cur_header;
    }
    if (lookup_symbol(header, id_name) == -1) {
        Entry *temp = malloc(sizeof(Entry));
        temp->index = entry_num[header->depth]++;
        temp->name = id_name;
        temp->kind = kind;
        temp->type = type;
        temp->scope = header->depth;
        temp->attribute = attribute;
        temp->next = NULL;
        header->tail->next = temp;
        header->tail = header->tail->next;
    }
    else {
        if(kind == "variable"){
            sprintf(msg, "Redeclared variable <%s>", id_name);
            flag = 3;
        }
        else if (kind == "function"){
            sprintf(msg, "Redeclared function <%s>", id_name);
            flag = 4;
        }    
    }
}
int lookup_symbol(Header *header, char *id_name) {
    if (header->root != NULL) {
        Entry *cur = header->root->next;
        while (cur != NULL) {
            if (strcmp(cur->name, id_name) == 0) {
                return cur->index;
            }
            else {
                cur = cur->next;
            }
        }
        return -1;
    }
    else {
        return -1;
    }
}
void dump_symbol() {
    if (cur_header->root != NULL) {
        printf("\n%-10s%-10s%-12s%-10s%-10s%-10s\n\n",
           "Index", "Name", "Kind", "Type", "Scope", "Attribute");
        Entry *cur = cur_header->root->next;
        while(cur != NULL) {
            printf("%-10d%-10s%-12s%-10s%-10d%-10s\n", cur->index, cur->name, cur->kind, cur->type, cur->scope, cur->attribute);
            Entry *temp = cur;
            cur = cur->next;
            free(temp);
            temp = NULL;
        }
        entry_num[depth] = 0;
    }
    cur_header = cur_header->previous;
    depth--;
}
