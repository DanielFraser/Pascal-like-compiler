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

vardcl	: idlist ':' type {$1.type = $3.type;}
	;

idlist	: idlist ',' ID {   int offset = NextOffset(1);

                            SymTabEntry* exists = lookup($3.str);
                            if (!exists)
                                insert($3.str, $$.type, offset);
                        }
        | ID	{
                    int offset = NextOffset(1);

                    SymTabEntry* exists = lookup($1.str);
                    if (!exists)
                        insert($1.str, $$.type, offset);
                }
	;


type	: ARRAY '[' ICONST ']' OF stype {  }

        | stype {$$.type = $1.type;}
	;

stype	: INT {$$.type = TYPE_INT;}
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
          THEN stmt 
  	  ELSE 
          stmt 
	;

ifhead : IF condexp {  }
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

wstmt	: WHILE  {  } 
          condexp {  } 
          DO stmt  {  } 
	;


astmt : lhs ASG exp             { 
 				  if (! ((($1.type == TYPE_INT) && ($3.type == TYPE_INT)) || 
				         (($1.type == TYPE_BOOL) && ($3.type == TYPE_BOOL)))) {
				         printf("\nb: %d and %d\n", $1.type == TYPE_BOOL, $3.type == TYPE_BOOL);
				    printf("*** ERROR ***: Assignment types do not match.\n");
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
                                  int offset = NextOffset(1);
				  
                                  $$.targetRegister = newReg2;
                                  $$.type = TYPE_INT;

                  SymTabEntry* exists = lookup($1.str);
                  if (!exists)
				    insert($1.str, TYPE_INT, offset);
				  offset =  lookup($1.str) -> offset;
				  emit(NOLABEL, LOADI, offset, newReg1, EMPTY);
				  emit(NOLABEL, ADD, 0, newReg1, newReg2);
				  
                         	  }


                                |  ID '[' exp ']' {   }
                                ;


exp	: exp '+' exp		{ int newReg = NextRegister();

                                  if (! (($1.type == TYPE_INT) && ($3.type == TYPE_INT))) {
    				    printf("*** ERROR ***: Operator types must be integer.\n");
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
                            printf("*** ERROR ***: Operator types must be integer.\n");
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
                            printf("*** ERROR ***: Operator types must be integer.\n");
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
                            printf("*** ERROR ***: Operator types must be boolean.\n");
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
                            printf("*** ERROR ***: Operator types must be boolean.\n");
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

	                          $$.targetRegister = newReg;
                              $$.type = TYPE_INT;
                              emit(NOLABEL, LOADAI, 0, var ->offset, newReg);
	                        }

        | ID '[' exp ']'	{   }
 


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


condexp	: exp NEQ exp		{  } 

        | exp EQ exp		{  } 

        | exp LT exp		{  }

        | exp LEQ exp		{  }

	| exp GT exp		{  }

	| exp GEQ exp		{  }

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




