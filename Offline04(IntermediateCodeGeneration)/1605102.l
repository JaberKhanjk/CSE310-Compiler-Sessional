%option noyywrap

%{
#include "1605102.h"
#include "y.tab.h"

using namespace std;

extern symbolTable *symTable;
extern symbolTable *sideTable;


string copyComment;
//string tempstr;
int commentLine = 0;

extern FILE *logout;
extern FILE *errorout;

extern int line_count;
extern int error_count;

void yyerror(char *);


void constToken(string type)
{
    if(type == "CONST_INT")
    {
        symbolInfo *symbol = new  symbolInfo(yytext, type);
        symbol-> variables-> intVal = atoi(yytext);
        symbol->setMarker(type);
        yylval.symbolType = symbol;
    }
    else if(type == "CONST_FLOAT")
    {
        symbolInfo *symbol = new  symbolInfo(yytext, type);
        symbol-> variables-> floatVal = atof(yytext);
        symbol->setMarker(type);
        yylval.symbolType = symbol;
    }
}



void operatorToken(string type)
{
    symbolInfo *symbol=new symbolInfo(yytext, type);
    yylval.symbolType=symbol;
}


void idToken(string type)
{
    symbolInfo *symbol = symTable->lookUp(yytext);
    if (symbol== NULL)
        {
            symbol= new symbolInfo(yytext,type);
        }
        yylval.symbolType= symbol;
}




%}

WHITESPACE [ \t\f\r\v]+ 

LETTER [a-zA-Z]

DIGIT [0-9]
FLOATLITERAL {DIGIT}*(\.{DIGIT}+)?(E[+-]?{DIGIT}+)?

IDENTIFIER [a-zA-Z_][a-zA-Z0-9_]*


STRING ["]([^"\\\n]|\\.|\\\n)*["]
UNFINISHED_STRING ["]([^"\\\n]|\\.|\\\n)*

  

SINGLELINE_COMMENT      "//"[^\n]*\n
SINGLE_MULTILINE_COMMENT    "//"([^\n]*(\\\n))+[^\n\\]+\n
MULTILINE_COMMENT       "/*"([^"*"]|"*"[^"/"])+"*/"
UNFINISHED_COMMENT             "/*"([^"*"]|"*"[^"/"])+[^"*/"]


TOO_MANY_DECIMAL_POINTS ({DIGIT}+\.)+{DIGIT}*
ILLFORMED_NUMBER {DIGIT}*(\.{DIGIT}*)?(E[+-]?{DIGIT}*\.{DIGIT}*)?
INVALID_ID {DIGIT}+({LETTER}|_)({LETTER}|{DIGIT}|_)*
MULTI_CHAR \'[a-zA-Z ][a-z A-Z]+\'
UNTERMINATED_CHAR (\'([a-zA-Z]*[^\'\n])?)|(\'\\\')
UNRECOGNIZED_CHAR (.)    
EMPTY_CHAR (\'\')

NEWLINE \n



%%



{NEWLINE} {line_count++;}

{WHITESPACE} {}

"if"        { return IF; }

"else"      { return ELSE; }

"for"       { return FOR; }

"while"     { return WHILE; }

"do"        { return DO; }

"break"     { return BREAK; }  
    
"int"       { return INT; }

"float"     { return FLOAT; }

"double"    { return DOUBLE; }

"void"      { return VOID; }

"return"    { return RETURN; }

"switch"    { return SWITCH; }

"case"      { return CASE; }

"default"   { return DEFAULT; }

"continue"  {  return CONTINUE; }

"println"   { return PRINTLN; }








"+"     |

"-"     {
            operatorToken("ADDOP");
            return ADDOP;
            
        }

"*" | 
"/" | 
"%"         {
               operatorToken("MULOP");
               return MULOP;
               
            }





"<"  |
"<=" |
">"  |
">=" |
"==" |
"!="     {
               operatorToken("RELOP");
               return RELOP;
               
         } 


"&&" | 
"||" {
               operatorToken("LOGICOP");
               return LOGICOP;
         
      }

"++" {return INCOP; } 

"--" {return DECOP;}

"=" { return ASSIGNOP; }

"!" { return NOT; }

"(" { return LPAREN;}

")" { return RPAREN; }

"{" { return LCURL; }

"}" { return RCURL; }

"[" { return LTHIRD; }

"]" { return RTHIRD; }

"," { return COMMA; }

";" { return SEMICOLON; }


 {SINGLELINE_COMMENT} {
    for(int i = 0; i < yyleng; i++)
    {
        if(yytext[i] == '\n') 
        line_count++;
    }
}



  {SINGLE_MULTILINE_COMMENT} {
    for(int i = 0; i < yyleng; i++)
    {
        if(yytext[i] == '\n')
        line_count++;
    }
}                   


{MULTILINE_COMMENT} {
    for(int i = 0; i < yyleng; i++)
    {
        if(yytext[i] == '\n') 
        line_count++;
    }
}



{STRING}   {


    for(int i = 0; i < yyleng; i++)
    {
        if(yytext[i] == '\n')
        line_count++;
    }

           }



        
{DIGIT}+    {
                constToken("CONST_INT");
                return CONST_INT;
            }


{FLOATLITERAL}   {

                constToken("CONST_FLOAT");
                return CONST_FLOAT;


                 }



{IDENTIFIER} {
                
             idToken("ID");
             return ID;
            
            }




{UNFINISHED_STRING} {
        

        fprintf(errorout,"Error at Line no %d: UNFINISHED STRING found %s\n",line_count,yytext);
        printf("Error at Line no %d: UNFINISHED STRING found %s\n",line_count,yytext);
     
        for (int i = 0; i <yyleng; i++ ) 
        {
        if(yytext[i]=='\n') line_count++;
        }
       

        error_count++;
    
        
        }


 
{UNFINISHED_COMMENT} {
    fprintf(errorout,"Error at Line no %d: UNFINISHED COMMENT found %s\n",line_count,yytext);
    printf("Error at Line no %d: UNFINISHED COMMENT found %s\n",line_count,yytext);
    error_count++;
    
    for(int i = 0; i < yyleng; i++)
    {
        if(yytext[i] == '\n') line_count++;
    }
}



{TOO_MANY_DECIMAL_POINTS} {
        
        fprintf(logout,"Error at Line no %d: TOO MANY DECIMAL POINTS found %s\n",line_count,yytext);
        printf("Error at Line no %d: TOO MANY DECIMAL POINTS found %s\n",line_count,yytext);
        error_count++;

        }

{ILLFORMED_NUMBER} {
        
        fprintf(errorout,"Error at Line no %d: ILLFORMED NUMBER found %s\n",line_count,yytext);
        printf("Error at Line no %d: ILLFORMED NUMBER found %s\n",line_count,yytext);
        error_count++;
        }


{INVALID_ID} {
        
        fprintf(errorout,"Error at Line no %d: INVALID IDENTIFIER found %s\n",line_count,yytext);
        printf("Error at Line no %d: INVALID IDENTIFIER found %s\n",line_count,yytext);
        error_count++;
        }



{MULTI_CHAR} {
        
        fprintf(errorout,"Error at Line no %d: MULTICHARACTER CONSTANT ERROR found %s\n",line_count,yytext);
        printf("Error at Line no %d: MULTICHARACTER CONSTANT ERROR found %s\n",line_count,yytext);
        error_count++;
        }

{UNTERMINATED_CHAR} {
        
        fprintf(errorout,"Error at Line no %d: UNTERMINATED CHARACTER found %s\n",line_count,yytext);
        printf("Error at Line no %d: UNTERMINATED CHARACTER found %s\n",line_count,yytext);
        error_count++;
        }


{UNRECOGNIZED_CHAR} {
        

        fprintf(errorout,"Error at Line no %d: UNRECOGNIZED CHARACTER found %s\n",line_count,yytext);
        printf("Error at Line no %d: UNRECOGNIZED CHARACTER found %s\n",line_count,yytext);
        error_count++;
 
        }


        

{EMPTY_CHAR} {
        
        fprintf(errorout,"Error at Line no %d: EMPTY CHARACTER found %s\n",line_count,yytext);
        printf("Error at Line no %d: EMPTY CHARACTER found %s\n",line_count,yytext);
        error_count++;
        }
%%