O   [0-7]
D   [0-9]
NZ  [1-9]
L   [a-zA-Z_]
A   [a-zA-Z_0-9]
H   [a-fA-F0-9]
HP  (0[xX])
E   ([Ee][+-]?{D}+)
P   ([Pp][+-]?{D}+)
FS  (f|F|l|L)
IS  (((u|U)(l|L|ll|LL)?)|((l|L|ll|LL)(u|U)?))
CP  (u|U|L)
SP  (u8|u|U|L)
ES  (\\(['"\?\\abfnrtv]|[0-7]{1,3}|x[a-fA-F0-9]+))
WS  [ \t\n\r\f\v]

%{
#define YYERROR_VERBOSE 1

#include <stdio.h>
#include <string.h>
#include "y.tab.h"

int yylex(void);
extern char *yytext;
extern void yyerror(const char *s);
extern void warn(const char *s);
extern int sym_type(const char *);

static void comment(void);
static int check_type(void);

extern void reprintToken(const char *value, int token);
extern void setSpecialState(int token);
%}

%option yylineno

%%
"/*"                    { comment(); }
"//".*                  { /* consume //-comment */ }
"#"(.*)                 { warn("Preprocesor directives are ignored."); reprintToken(yytext, 0); /* pass #-line */ }

"auto"					{ reprintToken("auto", AUTO); return(AUTO); }
"break"					{ reprintToken("break", BREAK); return(BREAK); }
"case"					{ reprintToken("case", CASE); return(CASE); }
"char"					{ reprintToken("char", CHAR); return(CHAR); }
"const"					{ reprintToken("const", CONST); return(CONST); }
"continue"				{ reprintToken("continue", CONTINUE); return(CONTINUE); }
"default"				{ reprintToken("default", DEFAULT); return(DEFAULT); }
"do"					{ reprintToken("do", DO); return(DO); }
"double"				{ reprintToken("double", DOUBLE); return(DOUBLE); }
"else"					{ reprintToken("else", ELSE); return(ELSE); }
"enum"					{ reprintToken("enum", ENUM); return(ENUM); }
"extern"				{ reprintToken("extern", EXTERN); return(EXTERN); }
"float"					{ reprintToken("float", FLOAT); return(FLOAT); }
"for"					{ reprintToken("for", FOR); return(FOR); }
"goto"					{ reprintToken("goto", GOTO); return(GOTO); }
"if"					{ reprintToken("if", IF); return(IF); }
"inline"				{ reprintToken("inline", INLINE); return(INLINE); }
"int"					{ reprintToken("int", INT); return(INT); }
"long"					{ reprintToken("long", LONG); return(LONG); }
"register"				{ reprintToken("register", REGISTER); return(REGISTER); }
"restrict"				{ reprintToken("restrict", RESTRICT); return(RESTRICT); }
"return"				{ reprintToken("return", RETURN); return(RETURN); }
"short"					{ reprintToken("short", SHORT); return(SHORT); }
"signed"				{ reprintToken("signed", SIGNED); return(SIGNED); }
"sizeof"				{ reprintToken("sizeof", SIZEOF); return(SIZEOF); }
"static"				{ reprintToken("static", STATIC); return(STATIC); }
"struct"				{ reprintToken("struct", STRUCT); return(STRUCT); }
"switch"				{ reprintToken("switch", SWITCH); return(SWITCH); }
"typedef"				{ reprintToken("typedef", TYPEDEF); return(TYPEDEF); }
"union"					{ reprintToken("union", UNION); return(UNION); }
"unsigned"				{ reprintToken("unsigned", UNSIGNED); return(UNSIGNED); }
"void"					{ reprintToken("void", VOID); return(VOID); }
"volatile"				{ reprintToken("volatile", VOLATILE); return(VOLATILE); }
"while"					{ reprintToken("while", WHILE); return(WHILE); }
"_Bool"                 { reprintToken("_Bool", BOOL); return BOOL; }
"_Complex"              { reprintToken("_Complex", COMPLEX); return COMPLEX; }
"_Imaginary"            { reprintToken("_Imaginary", IMAGINARY); return IMAGINARY; }
"_Thread_local"         { reprintToken("_Thread_local", THREAD_LOCAL); return THREAD_LOCAL; }
"__func__"              { reprintToken("__func__", FUNC_NAME); return FUNC_NAME; }
"@classdef"             { reprintToken("", CLASSDEF); setSpecialState(CLASSDEF); return CLASSDEF; }
"@data"                 { reprintToken("", CLASSDEF_DATA); setSpecialState(CLASSDEF_DATA); return CLASSDEF_DATA; }
"@mdef"                 { reprintToken("", CLASSDEF_MDEF); setSpecialState(CLASSDEF_MDEF); return CLASSDEF_MDEF; }
"@cldecl"               { reprintToken("", CLDECL); setSpecialState(CLDECL); return CLDECL; }
"@clexec"               { reprintToken("", CLEXEC); setSpecialState(CLEXEC); return CLEXEC; }
"@claccess"             { reprintToken("", CLACCESS); setSpecialState(CLACCESS); return CLACCESS; }
"@cltype"               { reprintToken("", CLTYPE); setSpecialState(CLTYPE); return CLTYPE; }

{L}{A}*					            { int type = check_type(); reprintToken(yytext, type); strcpy(yylval.sval, yytext); return type; }

{HP}{H}+{IS}?				        { reprintToken(yytext, I_CONSTANT); return I_CONSTANT; }
{NZ}{D}*{IS}?				        { reprintToken(yytext, I_CONSTANT); return I_CONSTANT; }
"0"{O}*{IS}?				        { reprintToken(yytext, I_CONSTANT); return I_CONSTANT; }
{CP}?"'"([^'\\\n]|{ES})+"'"		    { reprintToken(yytext, I_CONSTANT); return I_CONSTANT; }

{D}+{E}{FS}?				        { reprintToken(yytext, F_CONSTANT); return F_CONSTANT; }
{D}*"."{D}+{E}?{FS}?			    { reprintToken(yytext, F_CONSTANT); return F_CONSTANT; }
{D}+"."{E}?{FS}?			        { reprintToken(yytext, F_CONSTANT); return F_CONSTANT; }
{HP}{H}+{P}{FS}?			        { reprintToken(yytext, F_CONSTANT); return F_CONSTANT; }
{HP}{H}*"."{H}+{P}{FS}?			    { reprintToken(yytext, F_CONSTANT); return F_CONSTANT; }
{HP}{H}+"."{P}{FS}?			        { reprintToken(yytext, F_CONSTANT); return F_CONSTANT; }

({SP}?\"([^"\\\n]|{ES})*\"{WS}*)+	{ reprintToken(yytext, STRING_LITERAL); return STRING_LITERAL; }

"..."					{ reprintToken("...", ELLIPSIS) ; return ELLIPSIS; }
">>="					{ reprintToken(">>=", RIGHT_ASSIGN) ; return RIGHT_ASSIGN; }
"<<="					{ reprintToken("<<=", LEFT_ASSIGN) ; return LEFT_ASSIGN; }
"+="					{ reprintToken("+=", ADD_ASSIGN) ; return ADD_ASSIGN; }
"-="					{ reprintToken("-=", SUB_ASSIGN) ; return SUB_ASSIGN; }
"*="					{ reprintToken("*=", MUL_ASSIGN) ; return MUL_ASSIGN; }
"/="					{ reprintToken("/=", DIV_ASSIGN) ; return DIV_ASSIGN; }
"%="					{ reprintToken("%=", MOD_ASSIGN) ; return MOD_ASSIGN; }
"&="					{ reprintToken("&=", AND_ASSIGN) ; return AND_ASSIGN; }
"^="					{ reprintToken("^=", XOR_ASSIGN) ; return XOR_ASSIGN; }
"|="					{ reprintToken("|=", OR_ASSIGN) ; return OR_ASSIGN; }
">>"					{ reprintToken(">>", RIGHT_OP) ; return RIGHT_OP; }
"<<"					{ reprintToken("<<", LEFT_OP) ; return LEFT_OP; }
"++"					{ reprintToken("++", INC_OP) ; return INC_OP; }
"--"					{ reprintToken("--", DEC_OP) ; return DEC_OP; }
"->"					{ reprintToken("->", PTR_OP) ; return PTR_OP; }
"&&"					{ reprintToken("&&", AND_OP) ; return AND_OP; }
"||"					{ reprintToken("||", OR_OP) ; return OR_OP; }
"<="					{ reprintToken("<=", LE_OP) ; return LE_OP; }
">="					{ reprintToken(">=", GE_OP) ; return GE_OP; }
"=="					{ reprintToken("==", EQ_OP) ; return EQ_OP; }
"!="					{ reprintToken("!=", NE_OP) ; return NE_OP; }
";"					    { reprintToken(";", ';') ; return ';'; }
("{"|"<%")				{ reprintToken("{",'{') ; return '{'; }
("}"|"%>")				{ reprintToken("}",'}') ; return '}'; }
","					    { reprintToken(",",',') ; return ','; }
":"					    { reprintToken(":",':') ; return ':'; }
"="					    { reprintToken("=",'=') ; return '='; }
"("					    { reprintToken("(",'(') ; return '('; }
")"					    { reprintToken(")",')') ; return ')'; }
("["|"<:")				{ reprintToken("[",'[') ; return '['; }
("]"|":>")				{ reprintToken("]",']') ; return ']'; }
"."					    { reprintToken(".",'.') ; return '.'; }
"&"					    { reprintToken("&",'&') ; return '&'; }
"!"					    { reprintToken("!",'!') ; return '!'; }
"~"					    { reprintToken("~",'~') ; return '~'; }
"-"					    { reprintToken("-",'-') ; return '-'; }
"+"					    { reprintToken("+",'+') ; return '+'; }
"*"					    { reprintToken("*",'*') ; return '*'; }
"/"					    { reprintToken("/",'/') ; return '/'; }
"%"					    { reprintToken("%",'%') ; return '%'; }
"<"					    { reprintToken("<",'<') ; return '<'; }
">"					    { reprintToken(">",'>') ; return '>'; }
"^"					    { reprintToken("^",'^') ; return '^'; }
"|"					    { reprintToken("|",'|') ; return '|'; }
"?"					    { reprintToken("?",'?') ; return '?'; }

{WS}+					{ reprintToken(yytext, 0); }
.					    { yyerror("Bad character!"); /* discard bad characters */ }

%%

int yywrap(void)        /* called at end of input */
{
    return 1;           /* terminate now */
}

static void comment(void)
{
    int c;

    while ((c = input()) != 0)
        if (c == '*')
        {
            while ((c = input()) == '*')
                ;

            if (c == '/')
                return;

            if (c == 0)
                break;
        }
    yyerror("unterminated comment");
}

static int check_type(void)
{
    #define sym_type(identifier) IDENTIFIER /* we are faking symbol table as we don't have it */

    switch (sym_type(yytext))
    {
    case TYPEDEF_NAME:                /* previously defined */
        return TYPEDEF_NAME;
    case ENUMERATION_CONSTANT:        /* previously defined */
        return ENUMERATION_CONSTANT;
    default:                          /* includes undefined */
        return IDENTIFIER;
    }
}