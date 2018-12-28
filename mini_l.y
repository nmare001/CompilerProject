%{
 #include <stdio.h>
 #include <stdlib.h>
 #include <cstring>
 #include <vector>
 #include <iostream>
 #include <vector> 
 #include <string>
 #include <sstream>
 using namespace std;
 
 void yyerror(const char *msg);
 extern int currLine;
 extern int currPos;
 extern FILE * yyin;
 int yylex(void);
 
 int tempCount = 0;
 int labelCount = 0;
 int continues = 0;

 vector <string> variables;
 vector <string> equations;
 vector <string> CallStack;
 vector <string> TempStack;
 vector <string> code;
 vector <string> tempSave;
 
 void Operation(string);
 void allocSpace(int);
 int lastSpaceOpen();
 int lastContinue();
 
 //stuff i added for error checking
 vector<string> functions;
 bool checkVector (string input, vector<string> checkVec);
 vector<string> newVariables;
 vector<string> arrays;
 bool checkInLoop = false;
 vector<string> arrayVariables;

 vector<string> codeWords{"*", "/",  "+", "-",  "%",  "=",  "(",  ")", "end",  "program", "beginprogram",  "endprogram",  "elseif", "function", "beginparams", "endparams", "beginlocals", "endlocals", "beginbody", "endbody", "integer", "array", "[", "]", "[]", "of", "if", "then", "endif", "else", "while", "do", "foreach", "in", "beginloop", "endloop", "continue", "read", "write", "&&", "and", "or", "||", "true", "false", "return", "==", "!=", "<", ">", ">=", "<=", ";", ":", ","};

%}

%union{
  double dval;
  int ival;
  char* str;
}

%error-verbose
%start program
%token <str> MULT DIV PLUS MINUS MOD EQUAL L_PAREN R_PAREN END
%token <str> PROGRAM BEGIN_PROGRAM END_PROGRAM ELSEIF FUNCTION BEGIN_PARAMS END_PARAMS
%token <str> BEGIN_LOCALS END_LOCALS BEGIN_BODY END_BODY INTEGER ARRAY
%token <str> OF IF THEN ENDIF ELSE WHILE DO FOREACH IN BEGINLOOP ENDLOOP CONTINUE
%token <str> READ WRITE AND OR NOT TRUE FALSE RETURN
%token <str> EQ NEQ LT GT LTE GTE SEMICOLON COLON COMMA L_SQUARE_BRACKET R_SQUARE_BRACKET
%token <str> ASSIGN 
%token <dval> NUMBER
%token <str> IDENTIFIER

%type <str> idents
%type <str> ident
%type <str> relation-exp
%type <str> expression
%type <str> mult-exp
%type <str> term
%type <str> var
%type <str> paramDecl
%type <str> declaration

%left PLUS MINUS
%left MULT DIV
%nonassoc NOT
%nonassoc UMINUS


%% 
program       :   functions {
					if (checkVector("main", functions) != true) {
						yyerror("No main function defined");
					}
				  }
              ;
        
functions    :    
              |   function {newVariables.clear(), arrayVariables.clear();} functions 
              ;

function      :  FUNCTION ident SEMICOLON { 
                   functions.push_back(variables.back());
                   cout << "func " << variables.back() << endl; 
                   variables.pop_back();
                 } BEGIN_PARAMS paramDecls END_PARAMS BEGIN_LOCALS declarations END_LOCALS BEGIN_BODY statements END_BODY {
                   for(int i = 0; i < code.size(); i++){
                     cout << code.at(i) << endl;
                   }
                   code.clear();
                   cout << "endfunc\n\n";
                 }
              ;

paramDecls   :  
              |   paramDecl SEMICOLON paramDecls
              ;
        
paramDecl    :	idents COLON INTEGER  {
        				  if (checkVector(variables.back(), newVariables) == false) {
          					if (checkVector(variables.back(), codeWords) == false) {
          								cout << ". " << variables.back() << endl;
          								cout << "= " << variables.back() << ", $0" << endl; 
          						newVariables.push_back(variables.back());
          								variables.pop_back();
          					}
          					else {
          						yyerror("Trying to name a variable with the same name as a reserved keyword");
          					}
        				  }
        				  else {
        					  yyerror("Defining a variable more than once");
        				  }
        						} 
        		 | idents COLON ARRAY L_SQUARE_BRACKET NUMBER[num] R_SQUARE_BRACKET OF INTEGER {
        				  if ($num <= 0) {
        					  yyerror("Declaring an array of size <= 0");
        				  }
        				  else {
        						  cout << ".[] " << variables.back() << ", " << $num << endl;
							  arrayVariables.push_back(variables.back());
						 	  newVariables.push_back(variables.back());
        						  variables.pop_back();
        				  }
                }  
	          ;

declarations :  
              |   declaration SEMICOLON declarations
              ;
        
declaration  :	idents COLON INTEGER {
                  for( int i = 0; i < variables.size(); i++){
          					if (checkVector(variables.at(i), newVariables) == false) {
          						if (checkVector(variables.at(i), codeWords) == false) {
          										cout << ". " << variables.at(i) << endl;
								newVariables.push_back(variables.at(i));
          						}
          						else {
          							yyerror("Trying to name a variable with the same name as a reserved keyword");
          						}
          					}
          					 else {
          						yyerror("Defining a variable more than once");
          					}
                  }
                  variables.clear();
                }
              | idents COLON ARRAY L_SQUARE_BRACKET NUMBER[num] R_SQUARE_BRACKET OF INTEGER {
                  cout << ".[] " << variables.back() << ", " << $num << endl;
		  newVariables.push_back(variables.back());
		  arrayVariables.push_back(variables.back());
                  variables.pop_back();
                }  
		          ;
                       
statements   :   
              |  statement SEMICOLON statements 
              ;
                       
statement    :    var ASSIGN expression {
                    if(variables.back() == "[]"){ 
                      variables.pop_back();
                      string temp2 = TempStack.back();
                      TempStack.pop_back();
                      string temp1 = TempStack.back();
                      TempStack.pop_back();
                      
                      code.push_back("[]= " + variables.back() + ", " + temp1 + ", " + temp2);
                      variables.pop_back();
                    }
                    else {
                      code.push_back("= " + variables.back() + ", " + TempStack.back());
                      variables.pop_back();
                      TempStack.pop_back();
                    }
                  }
              |    if-statement ENDIF {
                    //code.push_back("endif");
                    code.push_back(": __label__" + to_string(labelCount+1));
                  	code.at(lastSpaceOpen()) = ": __label__" + to_string(labelCount);
                  	code.at(lastSpaceOpen()) = ":= __label__" + to_string(labelCount+1);
                  	code.at(lastSpaceOpen()) = "?:= __label__" + to_string(labelCount) + ", " + tempSave.back();
                  	labelCount+=2;
                  	tempSave.pop_back();                    
                  }
              |   if-statement ELSE {/*code.push_back("else");*/ allocSpace(2);} statements ENDIF { 
                    //code.push_back("endif");
                    code.push_back(": __label__" + to_string(labelCount+2));
                    code.at(lastSpaceOpen()) = ": __label__" + to_string(labelCount+1); 
                    code.at(lastSpaceOpen()) = ":=  __label__" + to_string(labelCount+2);
                  	code.at(lastSpaceOpen()) = ": __label__" + to_string(labelCount);
                  	code.at(lastSpaceOpen()) = ":= __label__" + to_string(labelCount+1);
                  	code.at(lastSpaceOpen()) = "?:= __label__" + to_string(labelCount) + ", " + tempSave.back();
                    labelCount+=3;
                    tempSave.pop_back();
                  }                
              |   WHILE {/*code.push_back("while");*/checkInLoop = true, code.push_back("OPEN_SPACE");} bool-exp {allocSpace(3);} BEGINLOOP statement SEMICOLON statements ENDLOOP{
                    //code.push_back("end while"); 
                    if(continues){
                      code.push_back(": __label__" + to_string(labelCount+3));
                      code.at(lastContinue()) = ":= __label__" + to_string(labelCount+3);
                    } 
                    code.push_back(":= __label__" + to_string(labelCount+2));
                    code.push_back(": __label__" + to_string(labelCount+1));
                  	code.at(lastSpaceOpen()) = ": __label__" + to_string(labelCount);
                  	code.at(lastSpaceOpen()) = ":= __label__" + to_string(labelCount+1);
                  	code.at(lastSpaceOpen()) = "?:= __label__" + to_string(labelCount) + ", " + tempSave.back();
                    code.at(lastSpaceOpen()) = ": __label__" + to_string(labelCount+2);
                  	labelCount+=3;
                    if(continues){
                      labelCount++;
                      continues--;
                    }
                  	tempSave.pop_back();                                                
                  }
              |   DO {/*code.push_back("do"); */code.push_back("OPEN_SPACE");} BEGINLOOP statement SEMICOLON statements ENDLOOP WHILE bool-exp { 
                    //code.push_back("End Do");
                    if(continues){
                      code.push_back(": __label__" + to_string(labelCount+1));
                      code.at(lastContinue()) = ":= __label__" + to_string(labelCount+1);
                    }                      
                  	code.push_back("?:= __label__" + to_string(labelCount) + ", " + TempStack.back());  
                    code.at(lastSpaceOpen()) = ": __label__" + to_string(labelCount);
                    labelCount++;
                    if(continues){
                      labelCount++;
                      continues--;
                    }
		    checkInLoop = false; 
                    TempStack.pop_back();                  
                  }                
              |   READ vars {
                    for(int i = 0; i < variables.size(); i++){
                      code.push_back(".< " + variables.at(i));
                    }
                    variables.clear();
                  }
              |   WRITE vars {
                    if(variables.back() == "[]") {
                      variables.pop_back();
                      code.push_back(".[]> " + variables.back() + ", " + TempStack.back());
                      TempStack.pop_back();
                      variables.pop_back();
                    }
                    else { 
                      for(int i = 0; i < variables.size(); i++){
                        code.push_back(".> " + variables.at(i));
                      }
                      variables.clear();
                    }
                  }
              |   CONTINUE {
                    if (checkInLoop == false) {
				yyerror("Using continue statement outside a loop");
		        }
		        else {
                    	//if(!inLoop) throw error
                    		code.push_back("CONTINUE");
                    		continues++;
			}
                  }
              |   RETURN expression {
                    code.push_back("ret " + TempStack.back());
                    TempStack.pop_back();
                  } 
              ;
              
vars         :    var 
              |   vars COMMA var 
              ;
      
var          :    ident {if (checkVector(variables.back(), newVariables) != true)  {
				yyerror("Using a variable without having first declared it");
				}
			  if (checkVector(variables.back(), arrayVariables) == true) {
				yyerror("Forgetting to specify an array index when using an array variable");
				}
			} 
              |   ident L_SQUARE_BRACKET expression R_SQUARE_BRACKET {
                    if (checkVector(variables.back(), newVariables) != true)  {
			yyerror("Using a variable without having first declared it");
		    }
		    else {
		    	if (checkVector(variables.back(), arrayVariables) == true) {
                    		variables.push_back("[]");
		    	}
			else {
				yyerror("Specifying an array index when using a regular integer variable");
			}
			}
		  
                  }
              ;
              
if-statement :    IF bool-exp {/*code.push_back("if");*/ allocSpace(3);} THEN statement SEMICOLON statements
              ;

bool-exp      :   relation-and-exp 
              |   bool-exp OR relation-and-exp  {Operation("|| ");}
              ;

relation-and-exp :  relation-exp 
                  |  relation-and-exp AND relation-exp {Operation("&& ");}
                  ;

relation-exp  :  NOT relation-exp %prec NOT 
              |  expression comp expression {
                  Operation(equations.back());
                  equations.pop_back();
                 }
              |  TRUE  { 
                    string temp = "__temp__" + to_string(tempCount);
                    code.push_back(". " + temp);
                    code.push_back("= " + temp + ", 1");
                    TempStack.push_back(temp);
                    ++tempCount;
                  }                  
              |  FALSE { 
                    string temp = "__temp__" + to_string(tempCount);
                    code.push_back(". " + temp);
                    code.push_back("= " + temp + ", 0");
                    TempStack.push_back(temp);
                    ++tempCount;
                  }  
              |  L_PAREN bool-exp R_PAREN 
              ;

comp         :   EQ   {equations.push_back("== ");} 
              |  NEQ  {equations.push_back("!= ");} 
              |  LT   {equations.push_back("< ");} 
              |  GT   {equations.push_back("> ");} 
              |  LTE  {equations.push_back("<= ");} 
              |  GTE  {equations.push_back(">= ");} 
              ;
             
expressions   :  expression 
              |  expression COMMA expressions  
              ;        
              
expression   :    mult-exp 
              |   expression PLUS mult-exp {Operation("+ ");}
              |   expression MINUS mult-exp {Operation("- ");}
              ;
              
mult-exp     :    term 
              |   mult-exp MULT term {Operation("* ");}
              |   mult-exp DIV term {Operation("/ ");}
              |   mult-exp MOD term {Operation("% ");}
              ;

term         :    MINUS term %prec UMINUS //{++tempCount, cout << "= __temp__ " << (tempCount - 1) << ",  " << $1 << endl;}
              |   NUMBER {
                    string temp = "__temp__" + to_string(tempCount);
                    ostringstream oss;
                    oss << $1;
                    code.push_back(". " + temp);
                    code.push_back("= " + temp + ", " + oss.str());
                    TempStack.push_back(temp);
                    ++tempCount;
                  }
              |   var {
                    string temp = "__temp__" + to_string(tempCount);
                    code.push_back(". " + temp);
                    if(variables.back() == "[]"){
                      variables.pop_back();
                      code.push_back("=[] " + temp + ", " + variables.back() + ", " + TempStack.back());
                      TempStack.pop_back();                      
                    }
                    else {
                      code.push_back("= " + temp + ", " + variables.back());
                    }
                    variables.pop_back();
                    TempStack.push_back(temp);
                    ++tempCount;
                  }
              |   L_PAREN expression R_PAREN 
              |   ident L_PAREN {CallStack.push_back($1);} expressions R_PAREN {
          					string s = CallStack.back();
          					s = s.substr(0,s.size()-2); //gets rid of L_PAREN
          					if (checkVector(s, functions) == true) {
          						code.push_back("param " + TempStack.back());
          						TempStack.pop_back();
          						string temp = "__temp__" + to_string(tempCount);
          						
          						code.push_back(". " + temp);
          					
          						code.push_back("call " + s + ", " + temp);
          					
          						TempStack.push_back(temp);
          						CallStack.pop_back();
          						variables.pop_back();
          						tempCount++;
          					}
          					 else {
          					yyerror("Calling a function which has not been defined");
          					}
          				} 
      			  |   ident L_PAREN {CallStack.push_back($1);} R_PAREN {
          					string s = CallStack.back();
          					s = s.substr(0,s.size()-2);
          					
          					if (checkVector(s, functions) == true) {
          						string temp = "__temp__" + to_string(tempCount);
          						
          						code.push_back(". " + temp);
          				
          						code.push_back("call " + s + ", " + temp);
          						
          						TempStack.push_back(temp);
          						CallStack.pop_back();
          						variables.pop_back();
          						tempCount++;
          					}
          					else {
          						yyerror("Calling a function which has not been defined");
          					}
                  }                        
              ;
              
idents       :    ident 
              |   ident COMMA idents 
		          ;

              
ident        :    IDENTIFIER    {variables.push_back($1);}
              ;
%%

int main(int argc, char **argv) {
   yyparse();
}

void yyerror(const char *msg) {
   printf("** Line %d, position %d: %s\n", currLine, currPos, msg);
}

void Operation(string op) {
 string temp = "__temp__" + to_string(tempCount);
 string src2 = TempStack.back();
 TempStack.pop_back();
 string src1 = TempStack.back();
 TempStack.pop_back();
 
 code.push_back(". " + temp);
 code.push_back(op + temp + ", " + src1 + ", " + src2);
 
 TempStack.push_back(temp);
 tempCount++;
}

void allocSpace(int spaces) {
  code.push_back("OPEN_SPACE");
  code.push_back("OPEN_SPACE");
  if(spaces == 3) {
    code.push_back("OPEN_SPACE"); 
    tempSave.push_back(TempStack.back());
    TempStack.pop_back();
  }
}

int lastSpaceOpen() {
 for(int i = code.size()-1; i >= 0; i--){
   if(code.at(i) == "OPEN_SPACE") {
     return i;
   }
 }
 return -1;
}

int lastContinue() {
 for(int i = code.size()-1; i >= 0; i--){
   if(code.at(i) == "CONTINUE") {
     return i;
   }
 }
 return -1;
}

//functions i added
bool checkVector(string input, vector<string> checkVec) {
	for (unsigned i = 0; i < checkVec.size(); ++i) {
		if (checkVec.at(i) == input) {
			return true;
		}
	}
	return false;
}
//error checks completed 1, 2, 3, 4, 5, 6, 7,  8
