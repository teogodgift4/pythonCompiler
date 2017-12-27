/* 
Grammar with semantics and type checking.
Lexical Analyser

*/

%{
#include <stdlib.h>
#include <string.h>
#include "pythonhead.h"
#include "pythonhead.tab.h"
int line = 1;
%}

D [0-9]
LETTER [a-zA-Z]
VARIABLE {LETTER}({LETTER}|{D})*
REAL {D}+\.{D}*
%%
"var" {return T_V_DECL;}
"begin" {return T_begin;}
"end" {return T_end;}
"if"  {return T_if;}
"then"  {return T_then;}
"else"  {return T_else;}
"true" {return T_true;} 
"false" {return T_false;} 
"and" {return T_and;}  
"or" {return T_or;}  
"not" {return T_not;}  
"program" {return T_program;}
"end_program" {return T_end_program;}

"int" {yylval.tokentype = type_integer; return T_type;}
"real" {yylval.tokentype = type_real; return T_type;}


"+" {return '+';}
"*" {return '*';}
"(" {return '(';}
")" {return ')';} 
"," {return ',';}
":" {return ':';}
";" {return ';';}
"/"  {return '/';}
"-"  {return '-';}
"="  {return '=';}
"<"  {return '<';}
">"  {return '>';}
"{"  {return '{';}
"}"  {return '}';}
":=" {return T_assign;}
 
{D}+ {yylval.i_val.intval = atoi(yytext); 
	  yylval.i_val.sval = strdup(yytext);  return T_num;}
	  
{REAL} {yylval.f_val.flval = atof(yytext); 
		yylval.f_val.sval = strdup(yytext); return T_real;}


{VARIABLE} {yylval.id = strdup(yytext); return T_id;}
\n  {line++;}
[ \t] { /* nothing */ }
. { 
	printf("Lexical Analysis: Unexpected String! :: %s. in line %d. \n",yytext,line); }
	
%%/* 
Grammar with semantics and type checking.
Lexical Analyser

*/

%{
#include <stdlib.h>
#include <string.h>
#include "smallLang.h"
#include "smallLang.tab.h"
int line = 1;
%}

D [0-9]
LETTER [a-zA-Z]
VARIABLE {LETTER}({LETTER}|{D})*
REAL {D}+\.{D}*
%%
"var" {return T_V_DECL;}
"begin" {return T_begin;}
"end" {return T_end;}
"if"  {return T_if;}
"then"  {return T_then;}
"else"  {return T_else;}
"true" {return T_true;} 
"false" {return T_false;} 
"and" {return T_and;}  
"or" {return T_or;}  
"not" {return T_not;}  
"program" {return T_program;}
"end_program" {return T_end_program;}

"int" {yylval.tokentype = type_integer; return T_type;}
"real" {yylval.tokentype = type_real; return T_type;}


"+" {return '+';}
"*" {return '*';}
"(" {return '(';}
")" {return ')';} 
"," {return ',';}
":" {return ':';}
";" {return ';';}
"/"  {return '/';}
"-"  {return '-';}
"="  {return '=';}
"<"  {return '<';}
">"  {return '>';}
"{"  {return '{';}
"}"  {return '}';}
":=" {return T_assign;}
 
{D}+ {yylval.i_val.intval = atoi(yytext); 
	  yylval.i_val.sval = strdup(yytext);  return T_num;}
	  
{REAL} {yylval.f_val.flval = atof(yytext); 
		yylval.f_val.sval = strdup(yytext); return T_real;}


{VARIABLE} {yylval.id = strdup(yytext); return T_id;}
\n  {line++;}
[ \t] { /* nothing */ }
. { 
	printf("Lexical Analysis: Unexpected String! :: %s. in line %d. \n",yytext,line); }
	
%%
