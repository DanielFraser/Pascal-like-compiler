%{
#include <stdio.h>
#include "attr.h"
#include "instrutil.h"
int yylex();
void yyerror(char * s);
#include "symtab.h"

FILE *outfile;
char *CommentBuffer;
 
%}

%union {tokentype token;
        regInfo targetReg;
        LabelList labels;
       }

%token PROG PERIOD VAR 
%token INT BOOL PRINT THEN IF DO  
%token ARRAY OF 
%token BEG END ASG  
%token EQ NEQ LT LEQ AND OR TRUE FALSE
%token ELSE
%token WHILE
%token <token> ID ICONST 

%type <targetReg> exp 
%type <targetReg> lhs 
%type <targetReg> type stype vardcl idlist
%type <labels> wstmt condexp ifhead

%start program

%nonassoc EQ NEQ LT LEQ GT GEQ 
%left '+' '-' AND
%left '*' OR

%nonassoc THEN
%nonassoc ELSE

%%
program : {emitComment("Assign STATIC_AREA_ADDRESS to register \"r0\"");
           emit(NOLABEL, LOADI, STATIC_AREA_ADDRESS, 0, EMPTY);} 
           PROG ID ';' block PERIOD { }
	;

block	: variables cmpdstmt { }
	;

variables: /* empty */
	| VAR vardcls { }
	;

vardcls	: vardcls vardcl ';' { }
	| vardcl ';' { }
	| error ';' { yyerror("***Error: illegal variable declaration\n");}  
	;

vardcl	: idlist ':' type {}
	;

idlist	: idlist ',' ID {addToList($3.str);}
        | ID	{addToList($1.str);}
	;


type	: ARRAY '[' ICONST ']' OF stype {
                            int offset = NextOffset($3.num);
                            Node* cursor = (Node*) getVarList();
                            insert(cursor -> string, $6.type, offset, TYPE_ARRAY);
                            clearList();
                            }

        | stype {
                 Node* cursor = (Node*) getVarList();
                 int offset = 0;
                 while(cursor)
                 {
                     offset = NextOffset(1);
                     insert(cursor -> string, $1.type, offset, TYPE_SCALAR);
                     cursor = (Node*) cursor -> next;
                 }
                 clearList();}
	;

stype	: INT  {$$.type = TYPE_INT;}

        | BOOL {$$.type = TYPE_BOOL;}
	;

stmtlist : stmtlist ';' stmt { }
	| stmt { }
        | error { yyerror("***Error: ';' expected or illegal statement \n");}
	;

stmt    : ifstmt { }
	| wstmt { }
	| astmt { }
	| writestmt { }
	| cmpdstmt { }
	;

cmpdstmt: BEG stmtlist END { }
	;

ifstmt :  ifhead 
          THEN stmt {$1.initial = NextLabel();
          emit(NOLABEL,BR,$1.initial,0,0);
          emit($1.endLbl,NOP,0,0,0);}
  	  ELSE 
          stmt {emit($1.initial,NOP,0,0,0);}
	;

ifhead : IF condexp {emit($2.cond,NOP,0,0,0);
                    $$.cond = $2.cond;
                    $$.endLbl = $2.endLbl;}
        ;

writestmt: PRINT '(' exp ')' { int printOffset = -4; /* default location for printing */
  	                         sprintf(CommentBuffer, "Code for \"PRINT\" from offset %d", printOffset);
	                         emitComment(CommentBuffer);
                                 emit(NOLABEL, STOREAI, $3.targetRegister, 0, printOffset);
                                 emit(NOLABEL, 
                                      OUTPUTAI, 
                                      0,
                                      printOffset, 
                                      EMPTY);
                               }
	;

wstmt	: WHILE  {emit(NextLabel(),NOP,0,0,0);}
          condexp {//Activate global var?
                    inductionVar = 1;
                    emit($3.cond,NOP,0,0,0);}
          DO stmt  {//Deactivate global var?
                    inductionVar = 0;
                    emit(NOLABEL,BR,$3.initial,0,0); emit($3.endLbl,NOP,0,0,0);}
	;


astmt : lhs ASG exp             { 
 				  if (! ((($1.type == TYPE_INT) && ($3.type == TYPE_INT)) || 
				         (($1.type == TYPE_BOOL) && ($3.type == TYPE_BOOL)))) {
				    printf("\n*** ERROR ***: Assignment types do not match.\n");
				  }

				  emit(NOLABEL,
                                       STORE, 
                                       $3.targetRegister,
                                       $1.targetRegister,
                                       EMPTY);
                                }
	;

lhs	: ID			{ /* BOGUS  - needs to be fixed */

                  int newReg1 = NextRegister();
                  int newReg2 = NextRegister();

                  SymTabEntry* exists = lookup($1.str);
                  if(!exists)
                  {
                    if(inductionVar)
                        printf("\n*** ERROR ***: Induction variable %s not declared.\n", $1.str);
                    else
                        printf("\n*** ERROR ***: Variable %s not declared.\n", $1.str);
                  }

                if(inductionVar && (exists -> type != TYPE_INT || exists -> var != TYPE_SCALAR))
                    printf("\n*** ERROR ***: Induction variable %s not a scalar of type integer.\n", $1.str);
                else if (exists -> var != TYPE_SCALAR)
                    printf("\n*** ERROR ***: Variable %s is not a scalar variable.\n", $1.str);

                  $$.type = exists -> type;
                  $$.targetRegister = newReg2;
				  int offset =  exists -> offset;
				  emit(NOLABEL, LOADI, offset, newReg1, EMPTY);
				  emit(NOLABEL, ADD, 0, newReg1, newReg2);
				  
                  }


                |  ID '[' exp ']'   {
                                        SymTabEntry* var = lookup($1.str);
                                         if(var -> var != TYPE_ARRAY)
                                            printf("\n*** ERROR ***: Variable %s is not an array variable.\n", $1.str);
                                        if($3.type != TYPE_INT)
                                            printf("\n*** ERROR ***: Array variable %s index type must be integer.\n", $1.str);


                                       if(!var)
                                          printf("\n*** ERROR ***: Variable %s not declared.\n", $1.str);
                                       int offset = var -> offset;
                                       int newRegs[5] = {NextRegister(),NextRegister(),NextRegister(),NextRegister()};
                                       emit(NOLABEL, LOADI, 4, newRegs[0], EMPTY);
                                       emit(NOLABEL, MULT, newRegs[0], $3.targetRegister, newRegs[1]);
                                       emit(NOLABEL, LOADI, offset,  newRegs[2], EMPTY);
                                       emit(NOLABEL, ADD, newRegs[1], newRegs[2], newRegs[3]);
                                       emit(NOLABEL, ADD, 0, newRegs[3], newRegs[4]);
                                       $$.type = var -> type;
                                       $$.targetRegister = newRegs[4];
                                    }
                                ;


exp	: exp '+' exp		{ int newReg = NextRegister();

                                  if (! (($1.type == TYPE_INT) && ($3.type == TYPE_INT))) {
    				                printf("\n*** ERROR ***: Operator types must be integer.\n");
                                  }
                                  $$.type = $1.type;

                                  $$.targetRegister = newReg;
                                  emit(NOLABEL, 
                                       ADD, 
                                       $1.targetRegister, 
                                       $3.targetRegister, 
                                       newReg);
                                }

        | exp '-' exp   { int newReg = NextRegister();

                          if (! (($1.type == TYPE_INT) && ($3.type == TYPE_INT))) {
                            printf("\n*** ERROR ***: Operator types must be integer.\n");
                          }
                          $$.type = $1.type;

                          $$.targetRegister = newReg;
                          emit(NOLABEL,
                               SUB,
                               $1.targetRegister,
                               $3.targetRegister,
                               newReg);
                        }

        | exp '*' exp	{ int newReg = NextRegister();

                          if (! (($1.type == TYPE_INT) && ($3.type == TYPE_INT))) {
                            printf("\n*** ERROR ***: Operator types must be integer.\n");
                          }
                          $$.type = $1.type;

                          $$.targetRegister = newReg;
                          emit(NOLABEL,
                               MULT,
                               $1.targetRegister,
                               $3.targetRegister,
                               newReg);
                        }

        | exp AND exp	{ int newReg = NextRegister();

                          if (! (($1.type == TYPE_BOOL) && ($3.type == TYPE_BOOL))) {
                            printf("\n*** ERROR ***: Operand type must be boolean.\n");
                          }
                          $$.type = $1.type;

                          $$.targetRegister = newReg;
                          emit(NOLABEL,
                               AND_INSTR,
                               $1.targetRegister,
                               $3.targetRegister,
                               newReg);
                        }

        | exp OR exp    { int newReg = NextRegister();

                           if (! (($1.type == TYPE_BOOL) && ($3.type == TYPE_BOOL))) {
                              printf("\n*** ERROR ***: Operand type must be boolean.\n");
                            }
                          $$.type = $1.type;

                          $$.targetRegister = newReg;
                          emit(NOLABEL,
                               OR_INSTR,
                               $1.targetRegister,
                               $3.targetRegister,
                               newReg);
                        }


        | ID			{ /* BOGUS  - needs to be fixed */
                              int newReg = NextRegister();
                              SymTabEntry* var = lookup($1.str);
                              if(var -> var != TYPE_SCALAR)
                                printf("\n*** ERROR ***: Variable %s is not a scalar variable.\n", $1.str);
                              if(!var)
                                printf("\n*** ERROR ***: Variable %s not declared.\n", $1.str);
	                          $$.targetRegister = newReg;
                              $$.type = var -> type;
                              emit(NOLABEL, LOADI, var -> offset, newReg, EMPTY);
	                        }

        | ID '[' exp ']'    {
                              if($3.type != TYPE_INT)
                                printf("\n*** ERROR ***: Array variable %s index type must be integer.\n", $1.str);

                              SymTabEntry* var = lookup($1.str);
                              if(var -> var != TYPE_ARRAY)
                                printf("\n*** ERROR ***: Variable %s is not an array variable.\n", $1.str);
                              if(!var)
                                printf("\n*** ERROR ***: Variable %s not declared.\n", $1.str);
                              int offset = var -> offset;
                              int newRegs[5] = {NextRegister(),NextRegister(),NextRegister(),NextRegister()};
                              emit(NOLABEL, LOADI, 4, newRegs[0], EMPTY);
                              emit(NOLABEL, MULT, newRegs[0], $3.targetRegister, newRegs[1]);
                              emit(NOLABEL, LOADI, offset,  newRegs[2], EMPTY);
                              emit(NOLABEL, ADD, newRegs[1], newRegs[2], newRegs[3]);
                              emit(NOLABEL, LOADAO, 0, newRegs[3], newRegs[4]);
                              $$.type = var -> type;
                              $$.targetRegister = newRegs[4];
                            }
 


	| ICONST                 { int newReg = NextRegister();
	                           $$.targetRegister = newReg;
				   $$.type = TYPE_INT;
				   emit(NOLABEL, LOADI, $1.num, newReg, EMPTY); }

        | TRUE                   { int newReg = NextRegister(); /* TRUE is encoded as value '1' */
	                           $$.targetRegister = newReg;
				   $$.type = TYPE_BOOL;
				   emit(NOLABEL, LOADI, 1, newReg, EMPTY); }

        | FALSE                   { int newReg = NextRegister(); /* FALSE is encoded as value '0' */
	                           $$.targetRegister = newReg;
				   $$.type = TYPE_BOOL;
				   emit(NOLABEL, LOADI, 0, newReg, EMPTY); }

	| error { yyerror("***Error: illegal expression\n");}  
	;


condexp	: exp NEQ exp	{
                        if($1.type != $3.type)
                            printf("\n*** ERROR ***: == or != operator with different types.\n");
                        int reg = NextRegister();
                        emit(NOLABEL, CMPNE, $1.targetRegister, $3.targetRegister, reg);
                        $$.cond = NextLabel();
                        $$.initial = $$.cond - 1;
                        $$.endLbl = NextLabel();
                        emit(NOLABEL, CBR, reg, $$.cond, $$.endLbl);
                       }

        | exp EQ exp	{
                        if($1.type != $3.type)
                            printf("\n*** ERROR ***: == or != operator with different types.\n");
                        int reg = NextRegister();
                        emit(NOLABEL, CMPEQ, $1.targetRegister, $3.targetRegister, reg);
                        $$.cond = NextLabel();
                        $$.initial = $$.cond - 1;
                        $$.endLbl = NextLabel();
                        emit(NOLABEL, CBR, reg, $$.cond, $$.endLbl);
                        }

        | exp LT exp	{
                        if($1.type != TYPE_INT || $3.type != TYPE_INT)
                            printf("\n*** ERROR ***: Relational operator with illegal type.\n");
                        int reg = NextRegister();
                        emit(NOLABEL, CMPLT, $1.targetRegister, $3.targetRegister,  reg);
                        $$.cond = NextLabel();
                        $$.initial = $$.cond - 1;
                        $$.endLbl = NextLabel();
                        emit(NOLABEL, CBR, reg, $$.cond, $$.endLbl);
                        }

        | exp LEQ exp	{if($1.type != TYPE_INT || $3.type != TYPE_INT)
                            printf("\n*** ERROR ***: Relational operator with illegal type.\n");
                        int reg = NextRegister();
                        emit(NOLABEL, CMPLE, $1.targetRegister, $3.targetRegister, reg);
                        $$.cond = NextLabel();
                        $$.initial = $$.cond - 1;
                        $$.endLbl = NextLabel();
                        emit(NOLABEL, CBR, reg, $$.cond, $$.endLbl);
                        }

	    | exp GT exp	{if($1.type != TYPE_INT || $3.type != TYPE_INT)
                            printf("\n*** ERROR ***: Relational operator with illegal type.\n");
                        int reg = NextRegister();
                        emit(NOLABEL, CMPGT, $1.targetRegister, $3.targetRegister,  reg);
                        $$.cond = NextLabel();
                        $$.initial = $$.cond - 1;
                        $$.endLbl = NextLabel();
                        emit(NOLABEL, CBR, reg, $$.cond, $$.endLbl);
                        }

	    | exp GEQ exp	{if($1.type != TYPE_INT || $3.type != TYPE_INT)
                            printf("\n*** ERROR ***: Relational operator with illegal type.\n");
                        int reg = NextRegister();
                        emit(NOLABEL, CMPGE, $1.targetRegister, $3.targetRegister, reg);
                        $$.cond = NextLabel();
                        $$.initial = $$.cond - 1;
                        $$.endLbl = NextLabel();
                        emit(NOLABEL, CBR, reg, $$.cond, $$.endLbl);
                        }

	| error { yyerror("***Error: illegal conditional expression\n");}  
        ;

%%

void yyerror(char* s) {
        fprintf(stderr,"%s\n",s);
        }


int
main(int argc, char* argv[]) {

  printf("\n     CS415 Spring 2018 Compiler\n\n");

  outfile = fopen("iloc.out", "w");
  if (outfile == NULL) { 
    printf("ERROR: cannot open output file \"iloc.out\".\n");
    return -1;
  }

  CommentBuffer = (char *) malloc(650);  
  InitSymbolTable();

  printf("1\t");
  yyparse();
  printf("\n");

  PrintSymbolTable();
  
  fclose(outfile);
  
  return 1;
}




