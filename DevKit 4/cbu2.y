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
	int label;
	int outlabel;
	int condition;
	struct nodeType *son;
	struct nodeType *brother;
	} Node;
	
	

	
int tsymbolcnt=0;
int errorcnt=0;
int stmtLabel = 0;
int conditionLabel =0;

FILE *yyin;
FILE *fp;

extern char symtbl[MAXSYM][MAXSYMLEN];
extern int maxsym;
extern int lineno;

void DFSTree(Node*);
Node* MakeOPTree(int, Node*, Node*);
Node* MakeNode(int, int);
Node* MakeListTree(Node*, Node*);
Node* MakeIFConditionTree(int, Node*, Node*, Node*);
Node* MakeWHILEConditionTree(int, Node*, Node*);

void codegen(Node* );
void prtcode(Node* );
int processCondition(Node*);


void	dwgen();
int		gentemp();
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
%token <c> ADD SUB MUL DIV ASSGN STMTEND START END ID2 IF ELSE WHILE DO PRINTNUM PRINTLN LT RT LTE RTE EE NE
%token <node> ID NUM ELSESTMTLIST IFMAINSTMTLIST WMAINSTMTLIST LOOPNODE GOFALSENODE GOTRUENODE
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
		|   PRINTNUM '(' expr ')' STMTEND {$$=MakeOPTree(PRINTNUM, $3, NULL);}
		|	PRINTLN '(' expr ')' STMTEND {$$=MakeOPTree(PRINTLN, $3, NULL);}
		|   IF '(' expr ')' '{' stmt_list '}' { $$ = MakeIFConditionTree(IF,$3, $6, NULL);}
		|   IF '(' expr ')' '{' stmt_list '}' ELSE '{' stmt_list '}' { $$ = MakeIFConditionTree(IF,$3, $6, $10);}
		|   WHILE '(' expr ')' '{' stmt_list '}' { $$ = MakeWHILEConditionTree(WHILE, $3, $6);}
		;
		
		
expr	:   expr ADD term	{ $$=MakeOPTree(ADD, $1, $3); }
		|	expr SUB term	{ $$=MakeOPTree(SUB, $1, $3); }
		|   expr MUL term   { $$=MakeOPTree(MUL, $1, $3); }
		|   expr DIV term   { $$=MakeOPTree(DIV, $1, $3); }
		|   expr LT term   { $$=MakeOPTree(LT, $1, $3); }
		|   expr RT term   { $$=MakeOPTree(RT, $1, $3); }
		|   expr LTE term   { $$=MakeOPTree(LTE, $1, $3); }
		|   expr RTE term   { $$=MakeOPTree(RTE, $1, $3); }
		|   expr EE term   { $$=MakeOPTree(EE, $1, $3); }
		|   expr NE term   { $$=MakeOPTree(NE, $1, $3); }
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

// 처음만들면 son에다가 붙임.
	if (operand1 == NULL){
		newnode = (Node *)malloc(sizeof (Node));
		newnode->token = newnode-> tokenval = STMTLIST;
		newnode->son = operand2;
		newnode->brother = NULL;
		return newnode;
		}
	else { //그담부턴 son의 부라더에
		node = operand1->son;
		while (node->brother != NULL) node = node->brother;
		node->brother = operand2;
		return operand1;
		}
}
	
	Node* MakeIFConditionTree(int type, Node* condition, Node* operand1, Node* operand2){
		
		
	  // LOOP 생성을 위해 Token표시
		operand1 -> token = IFMAINSTMTLIST;
		if(operand2 != NULL){
		operand2 -> token = ELSESTMTLIST;
		}
		
		
		//if, while문 Ast연결
		
		//condition 노드 설정
		//condition -> token = IFCONDITION;
		//condition -> tokenval = IFCONDITION;
		
		
		Node* newNode = (Node*)malloc(sizeof(Node));
		newNode->token = type;
		newNode -> tokenval = type;
		newNode -> brother = NULL;
		
		
		
		//go false 노드 설정 condition 실패시 처리, 비교연산은 stacksim에서 안되는것같음
		//GOMINUS 등 이용?
		
		Node* goFalseNode = (Node*)malloc(sizeof(Node));
		goFalseNode -> son = NULL;
		goFalseNode -> token = goFalseNode -> tokenval =  GOFALSENODE;
		
		
		// condition 조건 맞을시 label작업
		newNode -> outlabel = conditionLabel;
		operand1 -> outlabel = conditionLabel;
		if(operand2 != NULL){
		operand2 -> outlabel = conditionLabel;
		}
		// 조건 안맞는경우 label작업 
		stmtLabel = conditionLabel+2;
		
		
		condition -> outlabel = stmtLabel;
		// 얘 입장에선 들어옴
		goFalseNode -> label = stmtLabel;
		
		
		
		
		conditionLabel++;
		
		
		newNode -> son = condition;
		condition -> brother = operand1;
		operand1 -> brother = goFalseNode;
		goFalseNode -> brother = operand2;
		
		return newNode;
	}
	
	Node* MakeWHILEConditionTree(int type, Node* condition, Node* operand1){
		
		
		//if, while문 Ast연결
		
		
		Node* newNode = (Node*)malloc(sizeof(Node));
		newNode->token = type;
		newNode -> tokenval = type;
		newNode -> brother = NULL;
		
		operand1 -> token = WMAINSTMTLIST;
		operand1 -> tokenval = WMAINSTMTLIST;
		
		//condition 노드 설정
		//condition -> token = WCONDITION;
		//condition -> tokenval = WCONDITION;
		
		//if문과 컨디션 체크 반대
		switch(condition -> token){
			case LT:
			condition -> token = RTE;
			break;
			case RT:
			condition -> token = LTE;
			break;
			case LTE:
			condition -> token = RT;
			break;
			case RTE:
			condition -> token = LT;
			break;
			case EE:
			condition -> token = NE;
			break;
			case NE:
			condition -> token = EE;
			break;
			default:
			break;
		}
		
		
		//LABEL 삽입을 위한 노드 생성
		Node* loopNode = (Node*)malloc(sizeof(Node));
		loopNode -> token = loopNode -> tokenval = LOOPNODE;
		loopNode -> son = NULL;
		
		
		//go true 노드 설정 condition TRUE시 WHILE 끝내기, 비교연산은 stacksim에서 안되는것같음
		//GOMINUS 등 이용?
		
		Node* goTrueNode = (Node*)malloc(sizeof(Node));
		goTrueNode -> son = NULL;
		goTrueNode -> token = goTrueNode -> tokenval =  GOTRUENODE;
		
		
		
		// inlabel 작업
		loopNode -> label = conditionLabel;
		operand1 -> label = conditionLabel;
		
		stmtLabel = conditionLabel+2;
		// outlabel 작업
		
		condition -> outlabel =  stmtLabel;
		newNode -> outlabel = stmtLabel;
		
		conditionLabel++;

		//노드순서설정
		newNode -> son = loopNode;
		loopNode -> brother = condition;
		condition -> brother = goTrueNode;
		goTrueNode -> brother = operand1;
		
		
		
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
		case PRINTNUM:
			prtcode(node->son);
			fprintf(fp,"OUTNUM\n");
			break;
		case PRINTLN:
			prtcode(node->son);
			fprintf(fp,"OUTNUM\n");
			fprintf(fp, "PUSH 10\n");
			fprintf(fp, "OUTCH\n");
			break;
		case IFMAINSTMTLIST:
		//DFS stmtlist 문 트리 끝날때, 만약 condition 만족하지 못하면 나갈 자리생성	
			fprintf(fp, "GOTO out%d\n", node -> outlabel);
		
			break;
		case WMAINSTMTLIST:
			fprintf(fp, "GOTO in%d\n", node ->label);
			break;
		
		case ELSESTMTLIST:
			fprintf(fp, "GOTO out%d\n", node -> outlabel);
			break;
		
			//AST 에서 IF 타입인 노드가 stmtlist 보다 위에 있으므로 나중에 실행  => 맨 마지막에 입력됨 전체 나감
		case IF:
			fprintf(fp, "LABEL out%d\n", node -> outlabel);
			break;
		case WHILE:
			fprintf(fp, "LABEL out%d\n", node -> outlabel);
			break;
			
		case LOOPNODE:
			fprintf(fp, "LABEL in%d\n", node -> label);
			 break;
			 
		case GOFALSENODE:
			fprintf(fp, "LABEL out%d\n", node -> label);
			break;
		case LT:
			fprintf(fp, "-\n");
			fprintf(fp, "GOMINUS out%d\n", node -> outlabel);
			prtcode(node -> son);
			prtcode(node -> son -> brother);
			fprintf(fp, "-\n");
			fprintf(fp, "GOFALSE out%d\n", node -> outlabel);
			
			break;
		case RT:
			fprintf(fp, "-\n");
			fprintf(fp, "GOPLUS out%d\n", node -> outlabel);
			prtcode(node -> son);
			prtcode(node -> son -> brother);
			fprintf(fp, "-\n");
			fprintf(fp, "GOFALSE out%d\n", node -> outlabel);
			break;
		case LTE:
			fprintf(fp, "-\n");
			fprintf(fp, "GOMINUS out%d\n", node -> outlabel);
			break;
		case RTE:
			fprintf(fp, "-\n");
			fprintf(fp, "GOPLUS out%d\n", node -> outlabel);
			break;		
		case EE:
			fprintf(fp, "-\n");
			fprintf(fp, "GOTRUE out%d\n", node -> outlabel);
			break;
		case NE:
			fprintf(fp, "-\n");
			fprintf(fp, "GOFALSE out%d\n", node -> outlabel);
			break;
		default:
			break;
	}
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

