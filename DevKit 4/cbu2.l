%{
#include <string.h>
#include "cbu2.h"
#define _CRT_SECURE_NO_WARNINGS
#define MAXSYM	100
#define	MAXSYMLEN	20
char symtbl[MAXSYM][MAXSYMLEN];
int lineno=1;
int insertsym();
int maxsym=0;
char s[30];
int temp;
int cmpnum;

%}


sp		[ \t]
ws		{sp}+
nl		\n
eletter	[A-Za-z]
hletter	[\xb0-\xfe][\xa0-\xfe]
letter	({eletter}|{hletter})
digit	[0-9]
id		{letter}({letter}|{digit})*
%%
	
{ws}		{/* do nothing */}
{nl}		{lineno++; }
"+"			{return(ADD); }
"-"			{return(SUB); }
"*" 		{return(MUL); }
"/"			{return(DIV); }
":="		{return(ASSGN); }
";"			{return(STMTEND); }
"if"		{return(IF);}
"else"		{return(ELSE);}
"while"		{return(WHILE);}
"do"		{return(DO);}
"start"		{return(START); }
"end"		{return(END); }
"print"		{return(PRINT);}

"{" |
"}" |
"(" |
")" {return yytext[0];}

">"			{yylval.cmpNum = 1; return(CMP);}
"<"			{yylval.cmpNum = 2; return(CMP);}
">="		{yylval.cmpNum = 3; return(CMP);}
"<="		{yylval.cmpNum = 4; return(CMP);}
"=="		{yylval.cmpNum = 5; return(CMP);}
"!="		{yylval.cmpNum = 6; return(CMP);}


{id}	{strcpy(s, yytext); temp=insertsym(s); yylval.node=MakeNode(ID, temp); return(ID);}
{digit}+		{sscanf(yytext, "%d", &temp); yylval.node=MakeNode(NUM, temp); return(NUM);}

"."		{printf("invalid token %s\n", yytext); }





%%

int insertsym(s)
char *s;
{
int i;

	for(i=0;i<maxsym; i++) {
		if(strcmp(s, symtbl[i])==0) return(i);
		}
	if (i<MAXSYM-1) {
		strcpy(symtbl[maxsym],s);
		maxsym++;
		return(maxsym-1);
		}
	else
		{printf("symbol table overflow\n");}
	return(0);
}

yywrap() {}
