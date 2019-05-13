%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "token.h"
#include "astree.h"

int yylex(void);
extern int yylineno;
FILE *fIn;
int yyerror(char *str);

static ast_t *astRoot = NULL;
%}

%union {
    struct sStackType {
    unsigned char   flag;
        union {
        double         vNumber;
        char          *vStr;
        struct ast_s  *ast;
        }   u;
    }   s;
}

%type <s> program progelement conditional_statement statement expression block blockelement

%token <s> IDENTIFIER EOL NUMBER STRING OPLOGIC OPARITHMETIC EQUALS IF WHILE ELSE SIN COS TAN ASIN ACOS ATAN LOG LOG10 EXP WRITE READ EQ NEQ NOT LESS LEQ GREATER GEQ AND OR '(' ')'
%start program

%left OR
%left AND

%nonassoc EQ NEQ
%nonassoc LESS GREATER LEQ GEQ

%left '+' '-'
%left '*' '/' '%'

%right '^'

%right NOT


%%
program: program progelement
		 {
			 //Añadimos una línea al árbol, con etiqueta ";" y con hijos el nodo 
			 //correspondiente a esta línea y las líneas siguientes
			 astRoot = appR(';', astRoot, $2.u.ast);
		 }|
		 progelement
		 {
			 //printf("Valid program\n");
			 //Añadimos al árbol la primera línea del programa, con la etiqueta
			 // ";" y con hijos el nodo correspondiente a esta línea y el resto 
			 // del programa
			 astRoot = appR(';', astRoot, $1.u.ast);
		 };

progelement: conditional_statement|
				 //No sabemos qué tipo de statement va a ser, por tanto toma el valor que 
				 //se le asigne más adelante
				 $$ = $1;
			 statement ';' 
			 {
				 //No sabemos qué tipo de statement va a ser, por tanto toma el valor que 
				 //se le asigne más adelante
				 $$ = $1;
			 }|
			 ';'
			 {
				  //Línea vacía, no la añadimos al árbol de análisis
			      $$.flag = fAST;
			      $$.u.ast = NULL;
		     };

conditional_statement:	IF '(' expression ')' '{' block '}' |
			WHILE '(' expression ')' '{' block '}'

statement: 	IDENTIFIER '=' expression
			{	
				  //Le asignamos a este statement un nodo del árbol de análisis con la etiqueta "="
				  //Y como hijos un nodo que sólo contiene el nombre del identificador y que no tiene
				  //más hijos y el árbol asociado a la expresión de la derecha, que puede tener más hijos
				  //o no tenerlos y contener símplemente el valor de la derecha, si es por ejemplo un
				  //número o un identificador 
			      $$.flag = fAST;
			      $$.u.ast = mkNd('=', mkSlf(IDENTIFIER,$1.u.vStr), $3.u.ast);
		    }|
			
			READ '(' IDENTIFIER ')' 
			{
				  //Le asignamos a este statement un nodo con etiqueta READ y un sólo hijo, ya que sólo
				  //tiene un argumento. El hijo sólo contiene el nombre del identificador
			      $$.flag = fAST;
			      $$.u.ast = mkNd(READ, NULL, mkSlf(IDENTIFIER,$3.u.vStr));
		    }|
			READ '(' STRING ',' IDENTIFIER ')'
			{
				  //En la variante con dos argumentos, los hijos son el nodo con el nombre del identificador
				  //Y otro con el valor del String del primer argumento
			      $$.flag = fAST;
			      $$.u.ast = mkNd(READ, mkSlf(STRING, $3.u.vStr), mkSlf(IDENTIFIER,$5.u.vStr));
		    }|
			WRITE '(' IDENTIFIER ')' 
			{	
				  //Para la función write hacemos lo mismo que con READ
			      $$.flag = fAST;
			      $$.u.ast = mkNd(WRITE, NULL, mkSlf(IDENTIFIER,$3.u.vStr));
		    }|
			WRITE '(' STRING ',' IDENTIFIER ')'
			{		
				  $$.flag = fAST;
				  $$.u.ast = mkNd(WRITE, mkSlf(STRING, $3.u.vStr), mkSlf(IDENTIFIER,$5.u.vStr));

			};

expression:	IDENTIFIER 
			{	
				  //Asignamos a la expresión un nodo sin hijos que sólo contiene el 
				  //nombre del identificador
			      $$.flag = fAST;
			      $$.u.ast = mkSlf(IDENTIFIER,$1.u.vStr);
		    }|
			NUMBER 
			{	
				  //Asignamos a la expresión un nodo sin hijos que sólo contiene el 
				  //valor del número
			      $$.flag = fAST;
			      $$.u.ast = mkDlf(NUMBER,$1.u.vNumber);
		    }|
			'(' expression ')' 
			{
				//Devolvemos el nodo asociado a la expresión entre paréntesis
				$$ = $2;
			}|
			expression '+' expression 
			{	
				  //Añadimos un nodo con etiqueta "+" y como hijos los nodos asociados a cada
				  //expresión hija. Hacemos lo mismo con el resto de operadores, a excepción
				  //del NOT, que sólo tiene un hijo
			      $$.flag = fAST;
			      $$.u.ast = mkNd('+', $1.u.ast, $3.u.ast);
		    }|
			expression '-' expression 
			{	
			      $$.flag = fAST;
			      $$.u.ast = mkNd('-', $1.u.ast, $3.u.ast);
		    }|
			expression '/' expression 
			{	
			      $$.flag = fAST;
			      $$.u.ast = mkNd('/', $1.u.ast, $3.u.ast);
		    }|
			expression '%' expression 
			{	
			      $$.flag = fAST;
			      $$.u.ast = mkNd('%', $1.u.ast, $3.u.ast);
		    }|
			expression '*' expression 
			{	
			      $$.flag = fAST;
			      $$.u.ast = mkNd('*', $1.u.ast, $3.u.ast);
		    }|
			expression '^' expression 
			{	
			      $$.flag = fAST;
			      $$.u.ast = mkNd('^', $1.u.ast, $3.u.ast);
		    }|
			expression GREATER expression 
			{	
			      $$.flag = fAST;
			      $$.u.ast = mkNd(GREATER, $1.u.ast, $3.u.ast);
		    }|
			expression LESS expression 
			{	
			      $$.flag = fAST;
			      $$.u.ast = mkNd(LESS, $1.u.ast, $3.u.ast);
		    }|
			expression GEQ expression 
			{	
			      $$.flag = fAST;
			      $$.u.ast = mkNd(GEQ, $1.u.ast, $3.u.ast);
		    }|
			expression LEQ expression 
			{	
			      $$.flag = fAST;
			      $$.u.ast = mkNd(LEQ, $1.u.ast, $3.u.ast);
		    }|
			expression EQ expression 
			{	
			      $$.flag = fAST;
			      $$.u.ast = mkNd(EQ, $1.u.ast, $3.u.ast);
		    }|
			expression NEQ expression 
			{	
			      $$.flag = fAST;
			      $$.u.ast = mkNd(NEQ, $1.u.ast, $3.u.ast);
		    }|
			NOT expression 
			{	
			      $$.flag = fAST;
			      $$.u.ast = mkNd(AND, NULL, $2.u.ast);
		    }|
			expression AND expression 
			{	
			      $$.flag = fAST;
			      $$.u.ast = mkNd(AND, $1.u.ast, $3.u.ast);
		    }|
			expression OR expression 
			{	
			      $$.flag = fAST;
			      $$.u.ast = mkNd(OR, $1.u.ast, $3.u.ast);
		    }|
			SIN '(' expression ')'
			{
				  //Añadimos un nodo con etiqueta SIN y un sólo hijo, el nodo asociado a
				  //la expresión que es su único argumento. Hacemos esto para el resto de 
				  //funciones
				  $$.flag = fAST;
      			  $$.u.ast = mkNd(SIN,$3.u.ast,NULL);
			}|
			COS '(' expression ')'
			{
				  $$.flag = fAST;
      			  $$.u.ast = mkNd(COS,$3.u.ast,NULL);
			}|
			TAN '(' expression ')'
			{
				  $$.flag = fAST;
      			  $$.u.ast = mkNd(TAN,$3.u.ast,NULL);
			}|
			ASIN '(' expression ')'
			{
				  $$.flag = fAST;
      			  $$.u.ast = mkNd(ASIN,$3.u.ast,NULL);
			}|
			ACOS '(' expression ')'
			{
				  $$.flag = fAST;
      			  $$.u.ast = mkNd(ACOS,$3.u.ast,NULL);
			}|
			ATAN '(' expression ')'
			{
				  $$.flag = fAST;
      			  $$.u.ast = mkNd(ATAN,$3.u.ast,NULL);
			}|
			LOG '(' expression ')'
			{
				  $$.flag = fAST;
      			  $$.u.ast = mkNd(LOG,$3.u.ast,NULL);
			}|
			LOG10 '(' expression ')'
			{
				  $$.flag = fAST;
      			  $$.u.ast = mkNd(LOG10,$3.u.ast,NULL);
			}|
			EXP '(' expression ')'
			{
				  $$.flag = fAST;
      			  $$.u.ast = mkNd(EXP,$3.u.ast,NULL);
			};

block:	block blockelement|
		blockelement;


%%
int yyerror(char *str) {
	printf("Syntax error\n");
	printf("Line: %d\n", yylineno);
  	//prError(yylineno,"%s\n",str,NULL);
  return 1;
}

extern FILE *yyin;

int main(int argc, char *argv[]) {
	/*
  if (argc!=2) {
    puts("\nUsage: program <filename>\n");
    fflush(stdout);
    return 1;
  }

  if ((fIn=fopen(argv[1],"rb"))==NULL) {
    fprintf(stderr,"\nCannot open file: %s\n\n",argv[1]);
    fflush(stderr);
    return 1;
  }

  yyin = fIn;

  //setFilename( argv[1] );

  if (yyparse() != 0) {
    fclose(fIn);
    printf("Parsing aborted due to errors in input\n");
    //prError(yylineno,"Parsing aborted due to errors in input\n",NULL);
  }

  fclose(fIn);

  return 0;
  */
  yyparse();
  evaluate(astRoot);
  return 0;
}