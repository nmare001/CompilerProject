%{
  #include "y.tab.h"
  int currLine = 1, currPos = 1;
%}

DIGIT       [0-9]
LETTER      [a-zA-Z_]
IDENTIFIER  {LETTER}({LETTER}|{DIGIT}|([_](LETTER|DIGIT)))*

%%

"program"	      {return PROGRAM; currPos += yyleng;}
"beginprogram"	{return BEGIN_PROGRAM; currPos += yyleng;}
"endprogram"	  {return END_PROGRAM; currPos += yyleng;}
"elseif"        {return ELSEIF; currPos += yyleng;}
"function"	    {return FUNCTION; currPos += yyleng;}
"beginparams"   {return BEGIN_PARAMS; currPos += yyleng;}
"endparams"     {return END_PARAMS; currPos += yyleng;}
"beginlocals"   {return BEGIN_LOCALS; currPos += yyleng;}
"endlocals"     {return END_LOCALS; currPos += yyleng;}
"beginbody"     {return BEGIN_BODY; currPos += yyleng;}
"endbody"       {return END_BODY; currPos += yyleng;}
"integer"       {return INTEGER; currPos += yyleng;}
"array"         {return ARRAY; currPos += yyleng;}
"of"            {return OF; currPos += yyleng;}
"if"            {return IF; currPos += yyleng;}
"then"          {return THEN; currPos += yyleng;}
"endif"         {return ENDIF; currPos += yyleng;}
"else"          {return ELSE; currPos += yyleng;}
"while"         {return WHILE; currPos += yyleng;}
"do"            {return DO; currPos += yyleng;}
"foreach"       {return FOREACH; currPos += yyleng;}
"in"            {return IN; currPos += yyleng;}
"beginloop"     {return BEGINLOOP; currPos += yyleng;}
"endloop"       {return ENDLOOP; currPos += yyleng;}
"continue"      {return CONTINUE; currPos += yyleng;}
"read"          {return READ; currPos += yyleng;}
"write"         {return WRITE; currPos += yyleng;}
"and"           {return AND; currPos += yyleng;}
"or"            {return OR; currPos += yyleng;}
"not"           {return NOT; currPos += yyleng;}
"true"          {return TRUE; currPos += yyleng;}
"false"         {return FALSE; currPos += yyleng;}
"return"        {return RETURN; currPos += yyleng;}

"-"     {return MINUS; currPos += yyleng;}
"+"     {return PLUS; currPos += yyleng;}
"*"     {return MULT; currPos += yyleng;}
"/"     {return DIV; currPos += yyleng;}
"%"     {return MOD; currPos += yyleng;}

"=="    {return EQ; currPos += yyleng;}
"<>"    {return NEQ; currPos += yyleng;}
"<"     {return LT; currPos += yyleng;}
">"     {return GT; currPos += yyleng;}
"<="    {return LTE; currPos += yyleng;}
">="    {return GTE; currPos += yyleng;}

";"     {return SEMICOLON; currPos += yyleng;}
":"     {return COLON; currPos += yyleng;}
","     {return COMMA; currPos += yyleng;}
"["     {return L_SQUARE_BRACKET; currPos += yyleng;}
"]"     {return R_SQUARE_BRACKET; currPos += yyleng;}
":="    {return ASSIGN; currPos += yyleng;}
"("     {return L_PAREN; currPos += yyleng;}
")"     {return R_PAREN; currPos += yyleng;}


(\.{DIGIT}+)|({DIGIT}+(\.{DIGIT}*)?([eE][+-]?[0-9]+)?)   {currPos += yyleng; yylval.dval = atof(yytext); return NUMBER;}

{IDENTIFIER}    {currPos += yyleng; yylval.str = yytext; return IDENTIFIER; }

[ \t]+          {currPos += yyleng;}

"\n"            {currLine++; currPos = 1;}

"##"[^\n]*      {currLine++; currPos = 1;}

.       { printf("Unrecognized character: %s at  Line %d, Position %d\n", yytext, currLine, currPos ); exit(1);}

%%

