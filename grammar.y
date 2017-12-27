%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "sglib.h"
/* Just for being able to show the line number were the error occurs.*/
extern int line;

#define PARSER
#include "pythonhead.h"
#undef PARSER

/* Functions used during parsing (forward declarations) */
int addvar(char *,ParType);
ParType typeDefinition(ParType, ParType);
int lookup(char *);
ParType lookup_type(char *);

/* The Symbol Table*/
ST_TABLE symbolTable;
quadList L;
%}
/* Output informative error messages (bison Option) */
%error-verbose

/* Declaring the possible types of Symbols*/
%union{
  
   struct {
      int intval;
	  char * sval;} i_val;
   struct {
	  double flval;
	  char * sval;} f_val;
   char * id;
   char * name;
   ParType tokentype;
   struct {
	int i_value;
	ParType type; 
	char * place;} se;
   struct {
    quadList nextlist;} st;
   struct {
     quadList truelist;
	 quadList falselist;} st_cond;
   }  
 
/* Token declarations and their respective types */



%token <i_val> T_num
%token <f_val> T_real
%token '('
%token ')'

%token '}'
%token '{'

%token <tokentype> T_type
%token ':'
%token T_V_DECL "var"
%token T_begin "begin"
%token T_end "end"
%token T_if "if"
%token T_then "then"
%token T_else "else"
%token T_true "true"
%token T_false "false"
%token T_and "and"
%token T_or "or"
%token T_not "not"
%token <id> T_id
%token T_program "program"
%token T_end_program "end_program"

/* The type of non-terminal symbols*/
%type<se> expr 
%type<se> func
%type<st> stmt
%type<st> stmts
%type<st> blck
%type<st_cond> bool
%type<tokentype> vars
%type<name> relop

%type<st> cndl	
%type<st> asmt


%nonassoc T_assign 
%nonassoc '='
%nonassoc '>'
%nonassoc '<'

%left '+' '-' 
%left '*' '/'
%left "or"
%left "and"


%%
program: "program" T_id {genQuad("unit",$2,"-","-");symbolTable=NULL;} 		
			variable_declarations stmts "end_program" 
					{backpatch($5.nextlist,nextQuad);
					 genQuad("endu",$2,"-","-");}
	;
	
variable_declarations: /* empty */										
	| var_decl variable_declarations
	;

var_decl: "var" T_id vars {if (!addvar($2, $3)) {ERR_VAR_DECL($2,line);}}
	;
					
vars: ':' T_type ';' {$$ = $2;}
    | ',' T_id vars  {if (!addvar($2,$3)) {ERR_VAR_DECL($2,line);} $$ = $3;}
	;

blck: "begin" stmts "end" 	{$$.nextlist = $2.nextlist;}	
	|'{' stmts '}' 			{$$.nextlist = $2.nextlist;}	

/* A simple (very) definition of a list of statements.*/	
stmts: stmt ';' {$$.nextlist = $1.nextlist;}
	|  stmt ';' {backpatch($1.nextlist, nextQuad);} stmts 
						{$$.nextlist = $4.nextlist;}					
	;

stmt: cndl	{$$.nextlist = $1.nextlist;} 
	| asmt	{$$.nextlist = $1.nextlist;} 
	;		

cndl: "if"	bool "then" {backpatch($2.truelist,nextQuad);} blck 
						{$$.nextlist = mergelists($2.falselist,$5.nextlist);}
	;
	
asmt: T_id T_assign expr  {if (!($3.type = lookup_type($1))) 
                                      {ERR_VAR_MISSING($1,line);} 
						genQuad("=",$3.place, "-", strdup($1));
						$$.nextlist = NULL;}						
	;
	
bool: bool "or" 	{backpatch($1.falselist,nextQuad);} 	bool
					  {$$.truelist = mergelists($1.truelist,$4.truelist);
					   $$.falselist = $4.falselist;}
	| bool "and" 	{backpatch($1.truelist,nextQuad);} 		bool
					  {	$$.truelist = $4.truelist;
						$$.falselist = mergelists($1.falselist,$4.falselist); }
	| '(' bool ')'    {	$$.truelist = $2.truelist;
						$$.falselist = $2.falselist;}
	| expr relop expr {
				$$.truelist = makelist(nextQuad);	
				genQuad($2,$1.place,$3.place,"*");
				$$.falselist = makelist(nextQuad);
				genQuad("jump","-","-","*");
				}					
    | "true" {	$$.truelist = makelist(nextQuad);
				genQuad("jump","-","-","*");
				$$.falselist=NULL;}
	| "false" {	$$.falselist = makelist(nextQuad);
				genQuad("jump","-","-","*");
				$$.truelist=NULL;}
	;
	
relop: '>' 	{$$=">";} 
	| '<' 	{$$="<";}
	| '=' 	{$$="=";}

	
expr: func	 	{$$.type = type_integer; $$.place = $1.place;}				
	| T_num 	{$$.type = type_integer; $$.place = $1.sval;}
	| T_real 	{$$.type = type_real;}
	| T_id 		{if (!($$.type = lookup_type($1))) {ERR_VAR_MISSING($1,line);} 
				$$.place = strdup($1); 
				}
	| '(' expr ')' 	{$$.type = $2.type; $$.place = $2.place;}

	| expr '+' expr	{	$$.type = typeDefinition($1.type, $3.type);
	                    $$.place = newTemp($$.type);
						genQuad("+",$1.place, $3.place, $$.place);
					}
	| expr '-' expr	{	$$.type = typeDefinition($1.type, $3.type);
	                    $$.place = newTemp($$.type);
						genQuad("-",$1.place, $3.place, $$.place);
					}
	| expr '*' expr	{	$$.type = typeDefinition($1.type, $3.type);
	                    $$.place = newTemp($$.type);
						genQuad("*",$1.place, $3.place, $$.place);
					}
	| expr '/' expr	{	$$.type = typeDefinition($1.type, $3.type);
	                    $$.place = newTemp($$.type);
						genQuad("/",$1.place, $3.place, $$.place);
					}
	;
	
	
func: T_id '(' pars ')' {$$.place = newTemp(type_integer);
						genQuad("par","RET",$$.place,"-");
						genQuad("call","-","-",$1);
					 }
	;					
pars: /* nothing */ 
	| expr 		{genQuad("par",$1.place,"-","-");} rprs
	;
rprs: /* nothing */
	| "," expr 	{genQuad("par",$2.place,"-","-");} rprs
	;
	
%%

/* Function Definitions for Syntax and Semantic Analysis */
/* Type inferece regarding arithmetic expressions */

ParType typeDefinition(ParType Arg1, ParType Arg2)
{
	if (Arg1 == type_integer)
		{if (Arg2 == type_integer) {return type_integer;}
		 else if (Arg2 == type_real) {return type_real;}
		 }	 
	else if (Arg1 == type_real) 
		{if (Arg2 == type_integer || Arg2 == type_real) {return type_real;}
		}
	else {yyerror("Type missmatch"); return type_error;}
}
/* Adding a Variable entry to the ymbol table. */
int addvar(char *VariableName,ParType TypeDecl)
{    
	ST_ENTRY *newVar;
	
	if (!lookup(VariableName)) 
		{
		newVar = malloc(sizeof(ST_ENTRY));
		newVar->varname = VariableName;
		newVar->vartype = TypeDecl;
		SGLIB_LIST_ADD(ST_ENTRY, symbolTable, newVar, next_st_var);
		return 1;
		}
	else return 0; /* error */
}

/* Looking up a symbol in the symbol table. Returns 0 if symbol was not found. */

int lookup(char *VariableName){
	ST_ENTRY *var, *result;
	var = malloc(sizeof(ST_ENTRY));
	var->varname = strdup(VariableName);
	SGLIB_LIST_FIND_MEMBER(ST_ENTRY,symbolTable,var,ST_COMPARATOR,next_st_var, result); 
	free(var);
   if (result == NULL) {return 0;}
   else {return 1;} 
}

/* Looking up a symbol type in the symbol table. Returns 0 if symbol was not found. */

ParType lookup_type(char *VariableName)
{
	ST_ENTRY *var, *result;
	var = malloc(sizeof(ST_ENTRY));
	var->varname = strdup(VariableName);
	SGLIB_LIST_FIND_MEMBER(ST_ENTRY,symbolTable,var,ST_COMPARATOR,next_st_var, result); 
	free(var);
   if (result == NULL) {return type_error;}
   else {return result->vartype;} 
	
}
/* Printing the complete Symbol Table */
void print_symbol_table(void)
{
  ST_ENTRY *var;
  printf("\n Symbol Table Generated \n");
  SGLIB_LIST_MAP_ON_ELEMENTS(ST_ENTRY, symbolTable, var, next_st_var, {
    printf("ST:: Name %s Type %d \n", var->varname,var->vartype);
  });
}  
/* end of function declarations */

/* The usual yyerror */
int yyerror (const char * msg)
{
  fprintf(stderr, "PARSE ERROR: %s.on line %d.\n ", msg,line);
}

/* Other error Functions*/



/* Main */
int main ()
{ int parse_result;
  parse_result = yyparse();

  print_symbol_table();
  
  print_int_code();
  

  return parse_result;
}




