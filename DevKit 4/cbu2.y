%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define DEBUG	0



#define	 MAXSYM	100
#define	 MAXSYMLEN	20
#define	 MAXTSYMLEN	15
#define	 MAXTSYMBOL	MAXSYM/2

#define STMTLIST 500

typedef struct nodeType {
	int token;
	int tokenval;
    int LABEL;
    struct nodeType* condition;
	struct nodeType *son;
	struct nodeType *brother;
	} Node;
    
    

	
int tsymbolcnt=0;
int errorcnt=0;
int cnt=0;

FILE *yyin;
FILE *fp;

extern char symtbl[MAXSYM][MAXSYMLEN];
extern int maxsym;
extern int lineno;

void DFSTree(Node*);
Node* MakeOPTree(int, Node*, Node*);
Node* MakeNode(int, int);
Node* MakeListTree(Node*, Node*);
Node* MakeConditionTree(int, Node*, Node*, Node*);

void codegen(Node* );
void prtcode(Node* );
int processCondition(Node*);


void	dwgen();
int	    gentemp();
void	assgnstmt(int, int);
void	numassgn(int, int);
void	addstmt(int, int, int);
void	substmt(int, int, int);
int		insertsym(char *);
%}

%union{
    struct nodeType* node;
    int integer;
    double doub;
    int cmpNum;
    char c;
}

%nonassoc <cmpNum> CMP
%token <c> ADD SUB MUL DIV ASSGN STMTEND START END ID2 IF ELSE WHILE DO
%token <node> ID NUM
%type <node> stmt_list stmt expr term


%left ADD SUB
%left MUL DIV


%%
program	: START stmt_list END   { if (errorcnt==0) {codegen($2); dwgen();} }
		;

stmt_list: 	stmt_list stmt 	{$$=MakeListTree($1, $2);}
		|	stmt			{$$=MakeListTree(NULL, $1);}
		| 	error STMTEND	{ errorcnt++; yyerrok;}
		;

stmt	: 	ID ASSGN expr STMTEND	{ $1->token = ID2; $$=MakeOPTree(ASSGN, $1, $3);}
        |   IF '(' expr ')' '{' stmt_list '}' { $$ = MakeConditionTree(IF,$3, $6, NULL); fprintf(fp, "LABEL OUTIF%D", $3 -> LABEL)}
        |   IF '(' expr ')' '{' stmt_list '}' ELSE '{' stmt_list '}'{ $$ = MakeConditionTree(IF, $3, $6, $10);}
        ;
        
        
expr	:   expr CMP term   {$$=MakeOPTree(CMP, $1, $3);}
        |   expr ADD term	{ $$=MakeOPTree(ADD, $1, $3); }
		|	expr SUB term	{ $$=MakeOPTree(SUB, $1, $3); }
        |   expr MUL term   { $$=MakeOPTree(MUL, $1, $3); }
		|	term
		;


term	:	ID		{ /* ID node is created in lex 13*/ }
		|	NUM		{ /* NUM node is created in lex 14*/}
		;

%%
int main(int argc, char *argv[]) 
{
    
#ifdef YYDEBUG
  yydebug = 1;
#endif

	printf("\nsample CBU compiler v2.0\n");
	printf("2019038106 Choi Jehyeon Compiler project\n");
    int yydebug = 1;
    
	if (argc == 2)
		yyin = fopen(argv[1], "r");
	else {
		printf("Usage: cbu2 inputfile\noutput file is 'a.asm'\n");
		return(0);
		}
		
	fp=fopen("a.asm", "w");
	
	yyparse();
	
	fclose(yyin);
	fclose(fp);

	if (errorcnt==0) 
		{ printf("Successfully compiled. Assembly code is in 'a.asm'.\n");}
}

yyerror(s)
char *s;
{
	printf("%s (line %d)\n", s, lineno);
}


Node * MakeOPTree(int op, Node* operand1, Node* operand2)
{
Node * newnode;

	newnode = (Node *)malloc(sizeof (Node));
	newnode->token = op;
	newnode->tokenval = op;
	newnode->son = operand1;
	newnode->brother = NULL;
	operand1->brother = operand2;
	return newnode;
}

Node * MakeNode(int token, int operand)
{
Node * newnode;

	newnode = (Node *) malloc(sizeof (Node));
	newnode->token = token;
	newnode->tokenval = operand; 
	newnode->son = newnode->brother = NULL;
	return newnode;
}

Node * MakeListTree(Node* operand1, Node* operand2)
{
Node * newnode;
Node * node;

	if (operand1 == NULL){
		newnode = (Node *)malloc(sizeof (Node));
		newnode->token = newnode-> tokenval = STMTLIST;
		newnode->son = operand2;
		newnode->brother = NULL;
		return newnode;
		}
	else {
		node = operand1->son;
		while (node->brother != NULL) node = node->brother;
		node->brother = operand2;
		return operand1;
		}
}
    
    Node* MakeConditionTree(int type, Node* condition, Node* operand1, Node* operand2){
        
        Node* newNode = (Node*)malloc(sizeof(Node));
        
        newNode -> token = type;
        newNode -> condition;
        newNode -> son = operand1;
        newnode -> LABEL = cnt+1;
        newNode -> brother = NULL;
        operand1 -> brother = operand2;
        
        return newNode;
    }
    

void codegen(Node * root)
{
	DFSTree(root);
}

void DFSTree(Node * n)
{
	if (n==NULL) return;
	DFSTree(n->son);
	prtcode(n);
	DFSTree(n->brother);
	
}

void prtcode(Node* node)
{
	switch (node -> token) {
        case ID:
            fprintf(fp,"RVALUE %s\n", symtbl[node->tokenval]);
            break;
        case ID2:
            fprintf(fp, "LVALUE %s\n", symtbl[node->tokenval]);
            break;
        case NUM:
            fprintf(fp, "PUSH %d\n", node->tokenval);
            break;
        case ADD:
            fprintf(fp, "+\n");
            break;
        case SUB:
            fprintf(fp, "-\n");
            break;
        case MUL:
            fprintf(fp, "*\n");
            break;
        case DIV:
            fprintf(fp, "/\n");
            break;
        case ASSGN:
            fprintf(fp, ":=\n");
            break;
        case IF:
            if(processCondition(node) != 0)
            fprintf(fp,"1");
            else
            fprintf(fp,"0");
            fprintf(fp, "GOFALSE OUTIF%d\n", node->LABEL);
	case STMTLIST:
	default:
		break;
	};
}

    int processCondition(Node* node){
        
        Node* condition = node -> condition;
        int value = 0;
        int yydebug = 1;
        switch(condition -> token){
            case ID:
            value = node -> brother -> tokenval;
            break;
            case NUM:
            value = node -> tokenval;
            break;
            case '1':
            if(processCondition(condition->son) > processCondition(condition -> brother)){
                condition -> tokenval = 1;
                value = 1;
            }
            break;
                
            
        }
    
    return value;
    }


/*
int gentemp()
{
char buffer[MAXTSYMLEN];
char tempsym[MAXSYMLEN]="TTCBU";

	tsymbolcnt++;
	if (tsymbolcnt > MAXTSYMBOL) printf("temp symbol overflow\n");
	itoa(tsymbolcnt, buffer, 10);
	strcat(tempsym, buffer);
	return( insertsym(tempsym) ); // Warning: duplicated symbol is not checked for lazy implementation
}
*/
void dwgen()
{
int i;
	fprintf(fp, "HALT\n");
	fprintf(fp, "$ -- END OF EXECUTION CODE AND START OF VAR DEFINITIONS --\n");

// Warning: this code should be different if variable declaration is supported in the language 
	for(i=0; i<maxsym; i++) 
		fprintf(fp, "DW %s\n", symtbl[i]);
	fprintf(fp, "END\n");
}

