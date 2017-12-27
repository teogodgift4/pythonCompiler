#ifndef __PYTHONHEAD_H__
#define __PYTHONHEAD_H__
/* Definition of the supported types*/
typedef enum {type_error, type_integer, type_real, type_boolean} ParType;
typedef enum {type_variable, type_function} id_type;

/* These are needed here since they act as symbol attriutes. */
typedef struct qlist {
	int label;
	struct qlist *next_qlist;
	} quadel;

typedef quadel *quadList;

#endif

#ifdef PARSER
#define MAX_VAR_LEN 80
/* The following is the element of the symbol table. For simpicity reasons the symbol table is a linked list.*/
typedef struct st_var {
	char *varname;
	ParType vartype;
	struct st_var *next_st_var;
	} ST_ENTRY;

typedef ST_ENTRY *ST_TABLE;
/* definition required by the Lib (sglib ) for the linked lists used in the symbol table.  */
#define ST_COMPARATOR(e1,e2) (strcmp(e1->varname,e2->varname))
/* Error Messages Macros*/
#define ERR_VAR_DECL(VAR,LINE) printf("Variable :: %s on line %d. ",VAR,LINE); yyerror("Var already defined")

#define ERR_VAR_MISSING(VAR,LINE) printf("Variable %s NOT declared, on line %d.",VAR,LINE); yyerror("Variable Declation fault")

/* C Code for intermediate code generation */
/* -------------------------------------- */
/* The current label that will be assigned to the quad
and then current temporary variable number */
int current_label = 10;
int current_temp_var = 1;

typedef struct code_quad {
	int label;
	char * operation;
	char * opr_1;
	char * opr_2;
	char * opr_3;
	struct code_quad * next_quad; } quad;

typedef quad *code_Table;
code_Table INTERCODE = NULL;

#define nextQuad current_label
#define QUAD_COMPARATOR(e1, e2) (e1->label - e2->label)

/* Creates the next quad based on the 4 args. Increments
the current label counter as appropriate.*/
void genQuad(char *op, char *op1, char *op2, char *op3)
{
  quad *newquad;
  newquad = malloc(sizeof(quad));
  newquad->label = current_label;
  newquad->operation = strdup(op);
  newquad->opr_1 = strdup(op1);
  newquad->opr_2 = strdup(op2);
  newquad->opr_3 = strdup(op3);
  current_label++;
  SGLIB_LIST_ADD(quad, INTERCODE, newquad, next_quad);
}
/* Creating a temporary variable name.*/
char * newTemp(ParType t)
{ char * tempvar;
  tempvar = malloc(sizeof(char [11]));
  sprintf(tempvar,"t%d",current_temp_var);
  current_temp_var++;
  return tempvar;
}

/* Outputs the intermediate code. */
void print_int_code(void)
{
  quad * qd;
  printf("\n Intermediate Code Generated \n");

  SGLIB_LIST_REVERSE(quad, INTERCODE, next_quad);

  SGLIB_LIST_MAP_ON_ELEMENTS(quad, INTERCODE, qd, next_quad, {
    printf("%d :%s, %s , %s, %s\n", qd->label,qd->operation,qd->opr_1,qd->opr_2,qd->opr_3);
  });
}

/* -------------------------------------------------------------
Backpatching code ----------------------------------------------------------------- */
/* Creating a new List from an element. This new list will hold
information regarding which labels (num) have to be backpatched. */
quadList makelist(int quadLabel)
{
   quadel * newEntry;
   quadList newList;

   newList = NULL;
   newEntry = malloc(sizeof(quadel));
   newEntry->label = quadLabel;
   SGLIB_LIST_ADD(quadel, newList, newEntry, next_qlist);
   return newList;
}
/* Merges two lists of quad labels. */
quadList mergelists(quadList list1, quadList list2)
{
   quadList newList;
   newList = NULL;
   quadel * n;
   quadel * el;

   SGLIB_LIST_MAP_ON_ELEMENTS(quadel, list1, n, next_qlist,
	{
		el = malloc(sizeof(quadel));
	    el->label = n->label;

		SGLIB_LIST_ADD(quadel,newList,el,next_qlist);
		})

	SGLIB_LIST_MAP_ON_ELEMENTS(quadel, list2, n, next_qlist,
	{
		el = malloc(sizeof(quadel));
	    el->label = n->label;
		SGLIB_LIST_ADD(quadel,newList,el,next_qlist);
		})

   return newList;

}

/* Backpatching main function. Takes a list of quad labels and
a label (int) and makes appropriate changes. */

void backpatch(quadList ntflist, int QLabel)
{   quad * qelem, * jumpQuad;
    quadel * q;
	char temp[20]; /* needed for int to string conversion (C!) */

	qelem = malloc(sizeof(quad));
	SGLIB_LIST_MAP_ON_ELEMENTS(quadel, ntflist, q, next_qlist,
	{
        qelem->label = q->label;
	    SGLIB_LIST_FIND_MEMBER(quad,INTERCODE,qelem,QUAD_COMPARATOR,next_quad, jumpQuad);
		sprintf(temp,"%d",QLabel);
		printf("backpatch quad %d with %d\n",qelem->label,QLabel);
		jumpQuad->opr_3 = strdup(temp);
	});
   free(qelem);
}


#endif
