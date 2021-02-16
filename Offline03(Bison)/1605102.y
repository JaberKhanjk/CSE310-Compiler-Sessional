%{
#include "1605102.h"

using namespace std;

int yyparse(void);
int yylex(void);
// extern char* yytext;
extern FILE *yyin;
FILE *fp;
FILE *logout;
FILE *errorout;


symbolTable *symTable = new symbolTable();
//symbolTable *sideTable = new symbolTable(10);


int line_count=1;
int error_count=0;

int globalArrIndex = -1 , globalParamListSize = 0 , globalParamListSizeImplementing = 0;

string globalDeclarationType;
symbolInfo *globalParamList[100], *globalParamListImplementing[100];


void yyerror(const char* s)
{
	error_count++;
	fprintf(logout,"Error at line %d : %s\n",line_count,s);
	fprintf(errorout,"Error at line %d : %s\n",line_count,s);
	printf("Error at line %d : %s\n",line_count,s);
}

void printYYtext(const char *S)
{
	fprintf(logout, "%s\n\n",S);

}
void printIntoLogFile(char *S)
{
	fprintf(logout, "Line  %d : %s\n\n",line_count,S);
	
}

void printID(char *ID)
{
	fprintf(logout, "%s\n\n",ID);
}

void endPrint()
{
	fprintf(logout,"Total lines : %d\n",line_count);
	fprintf(logout,"Total errors : %d\n",error_count);
	fprintf(errorout,"Total errors : %d\n",error_count);

}

int logicHandler(float a, float b, string s)
{
	if(s == "==") return a == b;
	else if(s == "&&") return a && b;
	else if(s == ">=") return a >= b;
	else if(s == "<=") return a <= b;
	else if(s == "||") return a || b;
	else if(s == "!=") return a != b;
	else if(s == "<") return a < b;
	else if(s == ">") return a > b;
	
}

%}

%union 
{
	symbolInfo* symbolType;
	forVariables* valueType;
}


%error-verbose


%token IF ELSE FOR WHILE DO BREAK INT FLOAT DOUBLE VOID MAIN RETURN SWITCH CASE DEFAULT CONTINUE PRINTLN INCOP DECOP ASSIGNOP NOT LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON 
%token <symbolType> CONST_CHAR CONST_INT CONST_FLOAT ID ADDOP MULOP RELOP LOGICOP 

%type <symbolType> variable expression logic_expression rel_expression simple_expression term unary_expression factor
%type <valueType> type_specifier 

%left ADDOP
%left MULOP
%left LOGICOP
%left NOT
%left RELOP
%left ASSIGNOP

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%start start

%%

start : program
	{
		printIntoLogFile("start : program");
	}
	;

program : program unit 
	{
		printIntoLogFile("program : program unit");
	}
	| unit
	{
		printIntoLogFile("program : unit");
	}
	;
	
unit : var_declaration
	 {
	 	printIntoLogFile("unit : var_declaration");
	 }
     | func_declaration
     {
     	printIntoLogFile("unit : func_declaration");
     }
     | func_definition
     {
     	printIntoLogFile("unit : func_definition");
     }
     ;
     
func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
	{
		printIntoLogFile("func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON");
		symbolInfo* symbol = symTable->lookUp($2->getName(), "FUNCTION");
	
		if(symbol)
		{
			if(symbol->functions->declaration) 
			{
				yyerror("Multiple declaration of function.");
			}
			if(symbol->functions->definition) 
			{
				yyerror("Function already defined.");
			}
		}
		else
		{
			symbol = new symbolInfo($2->getName(), "ID", "FUNCTION");
			symbol->functions->declaration = true;
			symbol->functions->definition = false;
			symbol->functions->type = $1->type;
			symbol->functions->size = globalParamListSize;
			for(int i = 0; i < symbol-> functions-> size; i++)
			{
				symbol->functions->list[i] = globalParamList[i]->variables->type;
			}
			globalParamListSize = -1;
			symTable->insertIntoSymbolTable(symbol);
		}
	}
	| type_specifier ID LPAREN parameter_list RPAREN error
	| type_specifier ID LPAREN RPAREN SEMICOLON
	{
		printIntoLogFile("func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON");
		symbolInfo* symbol = symTable->lookUp($2->getName(), "FUNCTION");
	
		if(symbol)
		{
			if(symbol->functions->declaration) 
			yyerror("Multiple declaration of function.");
			if(symbol->functions->definition) 
			yyerror("Function already defined.");
		}
		else
		{
			symbol = new symbolInfo($2->getName(), "ID", "FUNCTION");
			symbol->functions->declaration = true;
			symbol->functions->definition = false;
			symbol->functions->type = $1->type;
			symbol->functions->size = 0;
			
			globalParamListSize = -1;
			symTable->insertIntoSymbolTable(symbol);
		}
	}
	| type_specifier ID LPAREN RPAREN error
	;
		 
func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement
{
		printIntoLogFile("func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement");
		symbolInfo* symbol = symTable->lookUp($2->getName(), "FUNCTION");
		if(symbol != NULL)
		{
			if(symbol->functions->definition) 
			yyerror("Function already defined.");

			else if(symbol->functions->declaration)
			{
				if(symbol->functions->type != $1->type) 
				yyerror("Return does not match.");
				
				if(symbol->functions->size != globalParamListSize) 
				yyerror("Parameter size does not match.");
				
				for(int i = 0; i < symbol->functions->size; i++)
				{
					if(symbol->functions->list[i] != globalParamList[i]->variables->type)
					{
						yyerror("Parameter does not match.");
						break;
					}
				}
				
			}
		}
		else
		{
			symbol = new symbolInfo($2->getName(), "ID", "FUNCTION");
			symbol->functions->declaration = true;
			symbol->functions->definition = true;
			symbol->functions->type = $1->type;
			symbol->functions->size = globalParamListSize;
			for(int i = 0; i < symbol-> functions-> size; i++)
			{
				symbol->functions->list[i] = globalParamList[i]->variables->type;
			}
			//cout<< globalParamList.at(1)->getName() <<endl;
			globalParamListSize = -1;
			//globalParamList.clear();
			symTable->insertIntoSymbolTable(symbol);
		}
	}

	| type_specifier ID LPAREN RPAREN compound_statement
	{
		printIntoLogFile("func_definition : type_specifier ID LPAREN RPAREN compound_statement");
		globalParamListSize = 0;
		symbolInfo* symbol = symTable->lookUp($2->getName(), "FUNCTION");
		if(symbol != NULL)
		{
			if(symbol->functions->definition) 
			yyerror("Function already defined.");

			else if(symbol->functions->declaration)
			{
				if(symbol->functions->type != $1->type) 
				yyerror("Return does not match.");
				
				if(symbol->functions->size != globalParamListSize) 
				yyerror("Parameter size does not match.");
				
			}
		}
		else
		{
			symbol = new symbolInfo($2->getName(), "ID", "FUNCTION");
			symbol->functions->declaration = true;
			symbol->functions->definition = true;
			symbol->functions->type = $1->type;
			symbol->functions->size = globalParamListSize;
			
			//cout<< globalParamList.at(1)->getName() <<endl;
			globalParamListSize = -1;
			//globalParamList.clear();
			symTable->insertIntoSymbolTable(symbol);
		}
	}
	;				


parameter_list  : parameter_list COMMA type_specifier ID
		{
			printIntoLogFile("parameter_list  : parameter_list COMMA type_specifier ID");
			symbolInfo* symbol = new symbolInfo($4->getName(), $4->getType());
			symbol->variables = $3;
			globalParamList[globalParamListSize++] = symbol;
		}
		| parameter_list COMMA type_specifier
		{
			printIntoLogFile("parameter_list  : parameter_list COMMA type_specifier");
			symbolInfo* symbol = new symbolInfo("NULL", "NULL");
			symbol->variables = $3;
			globalParamList[globalParamListSize++] = symbol;
		}
 		| type_specifier ID
 		{
			printIntoLogFile("parameter_list  : type_specifier ID");
			symbolInfo* symbol = new symbolInfo($2->getName(), $2->getType());
			symbol->variables = $1;
			globalParamListSize = 0;
			globalParamList[globalParamListSize++] = symbol;
		
		}
		| type_specifier
 		{
			printIntoLogFile("parameter_list  : type_specifier");
			symbolInfo* symbol = new symbolInfo("NULL","NULL");
			symbol->variables = $1;
			globalParamListSize = 0;
			globalParamList[globalParamListSize++] = symbol;
		}
 		;

 		
compound_statement : LCURL
					{
						symTable->enterScope(logout);
						if(globalParamListSize > 0)
						{
							for (int i = 0; i < globalParamListSize; i++)
							{
								symTable->insertIntoSymbolTable(globalParamList[i]);
							}
						}
						symTable->printCurrentScope(logout);
					} 
				statements RCURL
				{
					printIntoLogFile("compound_statement : LCURL statements RCURL");
					symTable->printAllScopes(logout);
					symTable->exitScope(logout);
				}
 		    | LCURL
 		    {
 		    	symTable->enterScope(logout);
 		    } RCURL
 		    {
 		    	printIntoLogFile("compound_statement : LCURL RCURL");
 		    	symTable->printAllScopes(logout);
 		    	symTable->exitScope(logout);
 		    }
 		    ;
 		    
var_declaration : type_specifier declaration_list SEMICOLON
		{
			printIntoLogFile("var_declaration : type_specifier declaration_list SEMICOLON");
		}
		|type_specifier declaration_list error
 		 ;
		
 		 
type_specifier	: INT
		{
			printIntoLogFile("type_specifier	: INT");
			forVariables *symbol = new forVariables("CONST_INT");
			symbol->intVal = 0;
			globalDeclarationType = "CONST_INT";
			$$ = symbol;
		}
 		| FLOAT
 		{
 			printIntoLogFile("type_specifier	: FLOAT");
 			forVariables *symbol = new forVariables("CONST_FLOAT");
 			symbol->floatVal= 0;
 			globalDeclarationType = "CONST_FLOAT";
 			$$ = symbol;
 		}
 		| VOID
 		{
 			printIntoLogFile("type_specifier	: VOID");
 			forVariables *symbol = new forVariables("VOID");
 			globalDeclarationType = "VOID";
 			$$ = symbol;
 		}
 		;
 		
declaration_list : declaration_list COMMA ID
			{
				printIntoLogFile("declaration_list : declaration_list COMMA ID");
				// string sym = $3->getName();
				// char *charArray = new char [sym.length()+1];
				// strcpy (charArray, sym.c_str());
				// printID(charArray);
				// printYYtext(yytext);
				// printf("%s\n",$3->getName());
				//symbolTable->printCurrentScope(logout);
				symbolInfo *symbol = symTable->lookUp($3->getName());
				if (symbol)
				{
					yyerror("Variable declared multiple times.");
				}
				else if (globalDeclarationType=="VOID")
				{
					yyerror("Variables cannot be declared void.");

				}
				else
				{
					$3->setType(globalDeclarationType);
					$3->setMarker(globalDeclarationType);
					symTable->insertIntoSymbolTable($3);
				}
			}
 		  | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
 		  {
 		  	printIntoLogFile("declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD");
 		//   	string sym = $3->getName();
			// char *charArray = new char [sym.length()+1];
			// strcpy (charArray, sym.c_str());
			// printID(charArray);
			// printYYtext(yytext);
			//fprintf(logout, "%s",yylex );
 		  	// printf("%s\n",$3->getName());
 		  	//symbolTable->printCurrentScope(logout);
 		  	symbolInfo *symbol = symTable->lookUp($3->getName(),"ARRAY");

 		  	if (symbol)
 		  	{
 		  		yyerror("Array declared multiple times.");
 		  	}
 		  	else if (globalDeclarationType == "VOID")
 		  	{
 		  		yyerror("Arrays cannot be declared void.");
 		  	}
 		  	else
 		  	{
 		  		symbol = new symbolInfo($3->getName(),globalDeclarationType,"ARRAY");
 		  		symbol->arrays->type = globalDeclarationType;
 		  		symbol->arrays->arrSize = atoi($5->getName().c_str());
 		  		for (int i = 0; i < symbol->arrays->arrSize; i++)
 		  		{
 		  			if (symbol->arrays->type == "CONST_INT")
 		  			{
 		  				symbol->arrays->intArr[i] = 0;
 		  			}
 		  			else if (symbol->arrays->type == "CONST_FLOAT");
 		  			{
 		  				symbol->arrays->floatArr[i]=0;
 		  			}
 		  		}
 		  		symTable->insertIntoSymbolTable(symbol);
 		  	}
 		  }
 		  | ID
 		  {
 		  	printIntoLogFile("declaration_list : ID");
 			// string sym = $1->getName();
			// char *charArray = new char [sym.length()+1];
			// strcpy (charArray, sym.c_str());
			// printID(charArray);
			// printYYtext(yytext);
			//fprintf(logout, "%s",yylex );
 		  	// printf("%s\n",$1->getName());
 		  	//symbolTable->printCurrentScope(logout);
 		  	symbolInfo *symbol = symTable->lookUp($1->getName());
 		  	if (symbol)
 		  	{
 		  		yyerror("Variable declared multiple times.");

 		  	}
 		  	else if (globalDeclarationType=="VOID")
				{
					yyerror("Variables cannot be declared void.");

				}
				else
				{
					$1->setType(globalDeclarationType);
					$1->setMarker(globalDeclarationType);
					symTable->insertIntoSymbolTable($1);
				}

 		  }
 		  | ID LTHIRD CONST_INT RTHIRD
 		  {
 		  	printIntoLogFile("declaration_list COMMA : ID LTHIRD CONST_INT RTHIRD");
 			// string sym = $1->getName();
			// char *charArray = new char [sym.length()+1];
			// strcpy (charArray, sym.c_str());
			// printID(charArray);
			// printYYtext(yytext);
 		  	// printf("%s\n",$1->getName());
 		  	//symbolTable->printCurrentScope(logout);
 		  	symbolInfo *symbol = symTable->lookUp($1->getName(),"ARRAY");

 		  	if (symbol)
 		  	{
 		  		yyerror("Array declared multiple times.");
 		  	}
 		  	else if (globalDeclarationType == "VOID")
 		  	{
 		  		yyerror("Arrays cannot be declared void.");
 		  	}
 		  	else
 		  	{
 		  		symbol = new symbolInfo($1->getName(),globalDeclarationType,"ARRAY");
 		  		symbol->arrays->type = globalDeclarationType;
 		  		symbol->arrays->arrSize = atoi($3->getName().c_str());
 		  		symTable->insertIntoSymbolTable(symbol);
 		  	}
 		  
 		  }
 		  ;
 		  
statements : statement
		{
			printIntoLogFile("statements : statement");

		}
	   | statements statement
	   {
	   	printIntoLogFile("statements : statements statement");
	   }
	   ;
	   
statement : var_declaration
			{
				printIntoLogFile("statement : var_declaration");
			}

	  | expression_statement
	  {
	  	printIntoLogFile("statement : expression_statement");
	  }

	  | compound_statement
	  {
	  	printIntoLogFile("statement : compound_statement");
	  }

	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement
	  {
	  	printIntoLogFile("statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement");

	  }

	  | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
	  {
	  	printIntoLogFile("statement : IF LPAREN expression RPAREN statement");
	  }

	  | IF LPAREN expression RPAREN statement ELSE statement
	  {
	  	printIntoLogFile("statement : IF LPAREN expression RPAREN statement ELSE statement");
	  }

	  | WHILE LPAREN expression RPAREN statement
	  {
	  	printIntoLogFile("statement : WHILE LPAREN expression RPAREN statement");
	  }

	  | PRINTLN LPAREN ID RPAREN SEMICOLON
	  {
	  	printIntoLogFile("statement : PRINTLN LPAREN ID RPAREN SEMICOLON");
	  }

	  | PRINTLN LPAREN ID RPAREN error

	  | RETURN expression SEMICOLON
	  {
	  	printIntoLogFile("statement : RETURN expression SEMICOLON");
	  }

	  |RETURN expression error
	  ;
	  
expression_statement 	: SEMICOLON	
			{
				printIntoLogFile("expression_statement : SEMICOLON");
			}	

			| expression SEMICOLON 
			{
				printIntoLogFile("expression_statement : expression SEMICOLON");
			}

			|expression error

			|error
			;
	  
variable : ID 		
			{
				printIntoLogFile("variable : ID");
				symbolInfo *symbol = symTable->lookUp($1->getName());
				if (!symbol)
				{
					yyerror("Variable not declared before initialization.");
				}
				else if (symbol->getMarker()=="ARRAY")
				{
					yyerror("Variable call does not match.");
				}
				else
				{
					$$ = symbol;
					symTable->printAllScopes(logout);
				}
			}
	 | ID LTHIRD expression RTHIRD 
	 {
	 	printIntoLogFile("variable : ID LTHIRD expression RTHIRD");
	 	symbolInfo *symbol = symTable->lookUp($1->getName(),"ARRAY");
	 	if (!symbol)
	 	{
	 		yyerror("Array not declared before initialization.");
	 	}
	 	else
	 	{
	 		if ($3->getMarker()=="CONST_INT")
	 		{
	 			globalArrIndex = $3->variables->intVal;
	 		}
	 		else if ($3->getMarker()=="CONST_FLOAT")
	 		{
	 			yyerror("Float type array index.");
	 		}

	 		if (globalArrIndex >= symbol->arrays->arrSize || globalArrIndex<0)
	 		{
	 			yyerror("Array index out of bound.");
	 		}
	 		else
	 		{
	 			$$ = symbol;
	 			symTable->printAllScopes(logout);
	 		}
	 	}
	 }
	 ;
	 
 expression : logic_expression	
 		{
 			printIntoLogFile("expression : logic_expression");
 			$$=$1;
 		}
	   | variable ASSIGNOP logic_expression 	
	   {
	   	printIntoLogFile("expression : variable ASSIGNOP logic_expression");
	   	if ($1->getMarker()=="CONST_INT")
	   	{
	   		if ($3->getMarker()=="CONST_INT")
	   		{
	   			$1->variables->intVal = $3->variables->intVal;
	   		}
	   		else if ($3->getMarker()=="CONST_FLOAT")
	   		{
	   			yyerror("Type casting error in assignment.");
	   		}
	   		else if ($3->getMarker()=="ARRAY" && $3->arrays->type=="CONST_INT")
	   		{
	   			$1->variables->intVal=$3->arrays->intArr[globalArrIndex];
	   		}
	   		else if ($3->getMarker()=="FUNCTION")
	   		{
	   			 if ($3->functions->type=="CONST_FLOAT")
	   			{
	   				yyerror("Type casting error in assignment.");
	   			}
	   			else if ($3->functions->type == "CONST_INT")
	   			{
	   				$1->variables->intVal=0;
	   			}
	   		}
	   	}
	   	else if ($1->getMarker()=="CONST_FLOAT")
	   	{
	   		if ($3->getMarker()=="CONST_INT")
	   		{
	   			$1->variables->floatVal=$3->variables->intVal;
	   		}   		
	   		else if ($3->getMarker()=="CONST_FLOAT")
	   		{
	   			$1->variables->floatVal=$3->variables->floatVal;
	   		}
	   		else if ($3->getMarker()=="ARRAY" && $3->arrays->type == "CONST_FLOAT")
	   		{
	   			$1->variables->floatVal=$3->arrays->floatArr[globalArrIndex];
	   		}
	   		else if ($3->getMarker()=="FUNCTION")
	   		{
	   			if ($3->functions->type=="CONST_INT")
	   			{
	   				yyerror("Type casting error in assignment.");
	   			}
	   			else if ($3->functions->type=="CONST_FLOAT")
	   			{
	   				$1->variables->floatVal=0;
	   			}
	   		}
	   	}

	   	else if($1->getMarker()=="ARRAY")
	   	{
	   		if ($1->arrays->type=="CONST_INT")
	   		{
	   			if($3->getMarker() == "CONST_FLOAT") 
	   			{
	   				yyerror("Type casting error in assignment");
	   			}
	   			else if ($3->getMarker()=="CONST_INT")
	   			{
	   				$1->arrays->intArr[globalArrIndex] = $3->variables->intVal;
	   			}

	   			else if($3->getMarker() == "ARRAY" && $3->arrays->type == "CONST_FLOAT")
	   			{
	   				yyerror("Type casting error in assignment");
	   			}

	   			else if($3->getMarker() == "ARRAY" && $3->arrays->type == "CONST_INT") 
	   				{
	   					$1->variables->intVal = $3->arrays->intArr[globalArrIndex];
	   				}



	   			else if($3->getMarker() == "FUNCTION")
				{
					    if($3->functions->type == "CONST_FLOAT") 
						{
							yyerror("Type casting error in assignment");
						}
						else if($3->functions->type == "CONST_INT") 
						{
							$1->variables->intVal = 0;
						} 
		
				}
	   		}

	   		if($1->arrays->type == "CONST_FLOAT")
			{
			    if($3->getMarker() == "CONST_INT") 
				{
					$1->arrays->floatArr[globalArrIndex] = $3->variables->intVal;
				}	
		
				else if($3->getMarker() == "CONST_FLOAT") 
				{
					$1->arrays->floatArr[globalArrIndex] = $3->variables->floatVal;
				} 
				else if($3->getMarker() == "ARRAY" && $3->arrays->type == "CONST_INT") 
				{
					$1->variables->floatVal = $3->arrays->intArr[globalArrIndex];
				}
		
				else if($3->getMarker() == "ARRAY" && $3->arrays->type == "CONST_FLOAT") 
				{
					$1->arrays->floatArr[globalArrIndex] = $3->arrays->floatArr[globalArrIndex];
				}
		
				else if($3->getMarker() == "FUNCTION")
				{
						if($3->functions->type == "CONST_FLOAT") 
						$1->variables->intVal = 0;
			
						else if($3->functions->type == "CONST_INT") 
						yyerror("Type casting error in assignment");
		
				}
			}
	   	}

	   }
	   ;
			
logic_expression : rel_expression 	
	{
		printIntoLogFile("logic_expression : rel_expression");
		$$ = $1;	
	}
		 | rel_expression LOGICOP rel_expression 
	
	{
		printIntoLogFile("logic_expression : rel_expression LOGICOP rel_expression");
		symbolInfo* symbol = new symbolInfo();
		
		symbol->setMarker("CONST_INT");
		
		if($1->getMarker()=="CONST_INT" && $3->getMarker()=="CONST_INT") 
		{
			symbol->variables->intVal = logicHandler($1->variables->intVal, $3->variables->intVal, $2->getName());
		}
		else if($1->getMarker()=="CONST_FLOAT" && $3->getMarker()=="CONST_INT") 
		{
			symbol->variables->intVal = logicHandler($1->variables->floatVal, $3->variables->intVal, $2->getName());
		}
		else if($1->getMarker()=="CONST_FLOAT" && $3->getMarker()=="CONST_FLOAT") 
		{
			symbol->variables->intVal = logicHandler($1->variables->floatVal, $3->variables->floatVal, $2->getName());
		}

		else if($1->getMarker()=="CONST_INT" && $3->getMarker()=="CONST_FLOAT") 
		{
			symbol->variables->intVal = logicHandler($1->variables->intVal, $3->variables->floatVal, $2->getName());
		}
		
		else if($1->getMarker() == "ARRAY" && $1->arrays->type == "CONST_INT")
		{
			if($3->getMarker() == "FUNCTION")
			{
				symbol->variables->intVal = logicHandler($1->arrays->intArr[globalArrIndex], $3->variables->floatVal, $2->getName());
			}

			else if($3->getMarker() == "CONST_INT") 
			{
				symbol->variables->intVal = logicHandler($1->arrays->intArr[globalArrIndex], $3->variables->intVal, $2->getName());
			}
			
			else if($3->getMarker() == "CONST_FLOAT") 
			{
				symbol->variables->intVal = logicHandler($1->arrays->intArr[globalArrIndex], $3->variables->floatVal, $2->getName());
			}
			

			
		}
		
		else if($3->getMarker() == "ARRAY" && $3->arrays->type == "CONST_INT")
		{
			if($1->getMarker() == "FUNCTION") 
			{
				symbol->variables->intVal = logicHandler($3->arrays->intArr[globalArrIndex], $1->variables->floatVal, $2->getName());
			}
			
			
			else if($1->getMarker() == "CONST_FLOAT")
			{
				symbol->variables->intVal = logicHandler($3->arrays->intArr[globalArrIndex], $1->variables->floatVal, $2->getName());
			}
			
			else if($1->getMarker() == "CONST_INT") 
			{
				symbol->variables->intVal = logicHandler($3->arrays->intArr[globalArrIndex], $1->variables->intVal, $2->getName());
			}
			
		}
	
		else if($1->getMarker() == "FUNCTION")
		{
			if($3->getMarker() == "CONST_FLOAT")
			{
				symbol->variables->intVal = logicHandler(0, $3->variables->floatVal, $2->getName());
			}
			
			else if($3->getMarker() == "CONST_INT") 
			{
				symbol->variables->intVal = logicHandler(0, $3->variables->intVal, $2->getName());
			}
		}
		
		else if($3->getMarker() == "FUNCTION")
		{
			if($1->getMarker() == "CONST_FLOAT") 
			{
				symbol->variables->intVal = logicHandler(0, $1->variables->floatVal, $2->getName());
			}
			
			else if($1->getMarker() == "CONST_INT") 
			{
				symbol->variables->intVal = logicHandler(0, $1->variables->intVal, $2->getName());
			}
			
		}
		$$ = symbol;
	}

		 ;
			
rel_expression	: simple_expression 
{
		printIntoLogFile("rel_expression	: simple_expression");
 		$$ = $1;	
	}
		| simple_expression RELOP simple_expression	
		{ 
		printIntoLogFile("rel_expression	: simple_expression RELOP simple_expression");
		
		symbolInfo* symbol = new symbolInfo();
		
		symbol->setMarker("CONST_INT");
		
		if($1->getMarker()=="CONST_INT" && $3->getMarker()=="CONST_INT") 
		{
			symbol->variables->intVal = logicHandler($1->variables->intVal, $3->variables->intVal, $2->getName());
		}
		else if($1->getMarker()=="CONST_FLOAT" && $3->getMarker()=="CONST_FLOAT") 
		{
			symbol->variables->intVal = logicHandler($1->variables->floatVal, $3->variables->floatVal, $2->getName());
		}

		else if($1->getMarker()=="CONST_INT" && $3->getMarker()=="CONST_FLOAT")
		{
			symbol->variables->intVal = logicHandler($1->variables->intVal, $3->variables->floatVal, $2->getName());
		}
		

		else if($1->getMarker()=="CONST_FLOAT" && $3->getMarker()=="CONST_INT") 
		{
			symbol->variables->intVal = logicHandler($1->variables->floatVal, $3->variables->intVal, $2->getName());
		}
		

		else if($1->getMarker() == "ARRAY" && $1->arrays->type == "CONST_INT")
		{
			if($3->getMarker() == "FUNCTION") 
			{
				symbol->variables->intVal = logicHandler($1->arrays->intArr[globalArrIndex], $3->variables->floatVal, $2->getName());
			}
			
			else if($3->getMarker() == "CONST_FLOAT") 
			{
				symbol->variables->intVal = logicHandler($1->arrays->intArr[globalArrIndex], $3->variables->floatVal, $2->getName());
			}
			
			else if($3->getMarker() == "CONST_INT") 
			{
				symbol->variables->intVal = logicHandler($1->arrays->intArr[globalArrIndex], $3->variables->intVal, $2->getName());
			}
			
			
		}
		
		else if($3->arrays->type == "CONST_INT" && $3->getMarker() == "ARRAY")
		{
			if($1->getMarker() == "FUNCTION") 
			{
				symbol->variables->intVal = logicHandler($3->arrays->intArr[globalArrIndex], $1->variables->floatVal, $2->getName());
			}
			
			else if($1->getMarker() == "CONST_FLOAT") 
			{
				symbol->variables->intVal = logicHandler($3->arrays->intArr[globalArrIndex], $1->variables->floatVal, $2->getName());
			}
			
			else if($1->getMarker() == "CONST_INT") 
			{
				symbol->variables->intVal = logicHandler($3->arrays->intArr[globalArrIndex], $1->variables->intVal, $2->getName());
			}
			
		}
	
		else if($1->getMarker() == "FUNCTION")
		{
			if($3->getMarker() == "CONST_FLOAT")
			{
				symbol->variables->intVal = logicHandler(0, $3->variables->floatVal, $2->getName());
			}

			else if($3->getMarker() == "CONST_INT") 
			{
				symbol->variables->intVal = logicHandler(0, $3->variables->intVal, $2->getName());
			}
		}
		
		else if($3->getMarker() == "FUNCTION")
		{
			if($1->getMarker() == "CONST_FLOAT")
			{
				symbol->variables->intVal = logicHandler(0, $1->variables->floatVal, $2->getName());
			}
		
			else if($1->getMarker() == "CONST_INT")
			{
				symbol->variables->intVal = logicHandler(0, $1->variables->intVal, $2->getName());
			} 
		}
		$$ = symbol;
	
	}	
	

		;
				
simple_expression : term 
			{
		printIntoLogFile("simple_expression : term");
		$$ = $1;
	}
		  | simple_expression ADDOP term 
		  {
		printIntoLogFile("simple_expression : simple_expression ADDOP term");
		symbolInfo* symbol = new symbolInfo();
		if( $3->getMarker() == "CONST_INT" && $1->getMarker() == "CONST_INT")
		{
			symbol->setMarker("CONST_INT");
			
			if($2->getName() == "+")
			{
				symbol->variables->intVal = $1->variables->intVal + $3->variables->intVal;
				$$ = symbol;
			}
			
			else if($2->getName() == "-")
			{
				symbol->variables->intVal = $1->variables->intVal - $3->variables->intVal;
				$$ = symbol;
			}
			
		}
		
		else if( $3->getMarker() == "CONST_FLOAT" || $1->getMarker() == "CONST_FLOAT")
		{
			symbol->setMarker("CONST_FLOAT");
			
			if($2->getName() == "+")
			{
				if( $3->getMarker() == "CONST_FLOAT" && $1->getMarker() == "CONST_FLOAT") 
				{
					symbol->variables->floatVal = $1->variables->floatVal + $3->variables->floatVal;
				}
				else if($3->getMarker() == "CONST_INT" && $1->getMarker() == "CONST_FLOAT")
				{
					symbol->variables->floatVal = $1->variables->floatVal + $3->variables->intVal;
				}
				
				else if($3->getMarker() == "CONST_FLOAT" && $1->getMarker() == "CONST_INT") 
				{
					symbol->variables->floatVal = $1->variables->intVal + $3->variables->floatVal;
				}
				
				$$ = symbol;
			}
			
			else if($2->getName() == "-")
			{	
				if( $3->getMarker() == "CONST_FLOAT" && $1->getMarker() == "CONST_FLOAT" ) 
				{
					symbol->variables->floatVal = $1->variables->floatVal + $3->variables->floatVal;
				}

				else if($3->getMarker() == "CONST_FLOAT" && $1->getMarker() == "CONST_INT") 
				{
					symbol->variables->floatVal = $1->variables->intVal + $3->variables->floatVal;
				}

				else if( $3->getMarker() == "CONST_INT" && $1->getMarker() == "CONST_FLOAT") 
				{
					symbol->variables->floatVal = $1->variables->floatVal + $3->variables->intVal;
				}
				

				
				
				
				$$ = symbol;
			}
		
		}
		
		else if($1->getMarker() == "ARRAY")
		{
			if($1->arrays->type == "CONST_INT" && $3->getMarker() == "CONST_INT")
			{
				symbol->setMarker("CONST_INT");
			
				if($2->getName() == "+")
				{
					symbol->variables->intVal = $1->arrays->intArr[globalArrIndex] + $3->variables->intVal;
					$$ = symbol;
				}
			
				else if($2->getName() == "-")
				{
					symbol->variables->intVal = $1->arrays->intArr[globalArrIndex] - $3->variables->intVal;
					$$ = symbol;
				}
			}
			
			else if( $3->getMarker() == "CONST_FLOAT" || $1->arrays->type == "CONST_FLOAT")
			{
				symbol->setMarker("CONST_FLOAT");
			
				if($2->getName() == "+")
				{
					if($1->arrays->type == "CONST_FLOAT" && $3->getMarker() == "CONST_FLOAT")
					{
						symbol->variables->floatVal = $1->arrays->floatArr[globalArrIndex] + $3->variables->floatVal;
					}
					else if($1->arrays->type == "CONST_INT" && $3->getMarker() == "CONST_FLOAT") 
					{
						symbol->variables->floatVal = $1->arrays->intArr[globalArrIndex] + $3->variables->floatVal;
					}
			
			
					else if($1->arrays->type == "CONST_FLOAT" && $3->getMarker() == "CONST_INT") 
					{
						symbol->variables->floatVal = $1->arrays->floatArr[globalArrIndex] + $3->variables->intVal;
					}
			

					$$ = symbol;
		
				}
		
				else if($2->getName() == "-")
				{
					if($1->arrays->type == "CONST_FLOAT" && $3->getMarker() == "CONST_FLOAT") 
					{
						symbol->variables->floatVal = $1->arrays->floatArr[globalArrIndex] - $3->variables->floatVal;
					}
			
					else if($1->arrays->type == "CONST_INT" && $3->getMarker() == "CONST_FLOAT") 
					{
						symbol->variables->floatVal = $1->arrays->intArr[globalArrIndex] - $3->variables->floatVal;
					}

					else if($1->arrays->type == "CONST_FLOAT" && $3->getMarker() == "CONST_INT") 
					{
						symbol->variables->floatVal = $1->arrays->floatArr[globalArrIndex] - $3->variables->intVal;
					}
			
					
			
					$$ = symbol;
		
				}
				
			}
			
		}

		else if($3->getMarker() == "ARRAY")
		{
			if($3->arrays->type == "CONST_INT" && $1->getMarker() == "CONST_INT")
			{
				symbol->setMarker("CONST_INT");
			
				if($2->getName() == "+")
				{
					symbol->variables->intVal = $3->arrays->intArr[globalArrIndex] + $1->variables->intVal;
					$$ = symbol;
				}
			
				else if($2->getName() == "-")
				{
					symbol->variables->intVal = $3->arrays->intArr[globalArrIndex] - $1->variables->intVal;
					$$ = symbol;
				}
				
			}
			
			else if($3->arrays->type == "CONST_FLOAT" || $1->getMarker() == "CONST_FLOAT")
			{
				symbol->setMarker("CONST_FLOAT");
			
				if($2->getName() == "+")
				{
					if($3->arrays->type == "CONST_FLOAT" && $1->getMarker() == "CONST_FLOAT") 
					{
						symbol->variables->floatVal = $1->variables->floatVal + $3->arrays->floatArr[globalArrIndex];
					}
			
					else if($3->arrays->type == "CONST_INT" && $1->getMarker() == "CONST_FLOAT") 
					{
						symbol->variables->floatVal = $1->variables->floatVal + $3->arrays->intArr[globalArrIndex];
					}

					else if($3->arrays->type == "CONST_FLOAT" && $1->getMarker() == "CONST_INT") 
					{
						symbol->variables->floatVal =  $1->variables->intVal + $3->arrays->floatArr[globalArrIndex];
					}
			
					
			
					$$ = symbol;
		
				}
		
				else if($2->getName() == "-")
				{	
					if($3->arrays->type == "CONST_FLOAT" && $1->getMarker() == "CONST_FLOAT") 
					{symbol->variables->floatVal = $1->variables->floatVal - $3->arrays->floatArr[globalArrIndex];}
			
					else if($3->arrays->type == "CONST_FLOAT" && $1->getMarker() == "CONST_INT") 
					{symbol->variables->floatVal =  $1->variables->intVal - $3->arrays->floatArr[globalArrIndex];}
			
					else if($3->arrays->type == "CONST_INT" && $1->getMarker() == "CONST_FLOAT") 
					{symbol->variables->floatVal = $1->variables->floatVal - $3->arrays->intArr[globalArrIndex];}
			
					$$ = symbol;
				
				}
			}
		
			else if ($1->getMarker() == "FUNCTION" || $3->getMarker() == "FUNCTION")
			{
				symbol->setMarker("CONST_INT");
				if($2->getName() == "+") 
				{
					if($1->getMarker() == "FUNCTION")
					{
						$$=$3; 
					}
					else
					{
						$$ = $1;
					}
				}
				else if($2->getName() == "-")
				{
					if($1->getMarker() == "FUNCTION")
					{
						if($3->getMarker() == "CONST_FLOAT")
						{
							$3->variables->floatVal *= -1;
							$$ = $3;
						}
						
						
						else if($3->getMarker() == "CONST_INT")
						{
							$3->variables->intVal *= -1;
							$$ = $3;
						}
						
						else if($3->getMarker() == "ARRAY")
						{
							if($3->arrays->type == "CONST_FLOAT")
							{
								$3->arrays->floatArr[globalArrIndex] *= -1;
								$$ = $3;
							}
							
							else if($3->arrays->type == "CONST_INT")
							{
								$3->arrays->intArr[globalArrIndex] *= -1;
								$$ = $3;
							} 	
						}
						
					}
					else
					{
						$$ = $1;
					}
				}
			}
		}
	}
		  ;
					
term :	unary_expression
		{
		printIntoLogFile("term : unary_expression");
	 	$$ = $1;
	}
     |  term MULOP unary_expression
     { 
    	printIntoLogFile("term : term MULOP unary_expression");
    	symbolInfo* symbol = new symbolInfo();
		
		if( $3->getMarker() == "CONST_INT" && $1->getMarker() == "CONST_INT")
		{
			symbol->setMarker("CONST_INT");
			
			if($2->getName() == "*")
			{
				symbol->variables->intVal = $1->variables->intVal * $3->variables->intVal;
				$$ = symbol;
			}
			
			else if($2->getName() == "/")
			{
				if(!$3->variables->intVal) 
				yyerror("Cannot be divided by zero");
				else 
				{
					symbol->variables->intVal = $1->variables->intVal / $3->variables->intVal;
					$$ = symbol;
				}
			}
			
			else if($2->getName() == "%")
			{
				if(!$3->variables->intVal) 
				yyerror("Cannot be divided by zero");
				else 
				{
				
					symbol->variables->intVal = $1->variables->intVal % $3->variables->intVal;
					$$ = symbol;
				}
			}
		}
		
		else if($1->getMarker() == "CONST_FLOAT" || $3->getMarker() == "CONST_FLOAT")
		{
			symbol->setMarker("CONST_FLOAT");
			
			if($2->getName() == "*")
			{
				if($1->getMarker() == "CONST_FLOAT" && $3->getMarker() == "CONST_FLOAT") 
				{
					symbol->variables->floatVal = $1->variables->floatVal * $3->variables->floatVal;
				}
				
				else if($1->getMarker() == "CONST_INT" && $3->getMarker() == "CONST_FLOAT") 
				{
					symbol->variables->floatVal = $1->variables->intVal * $3->variables->floatVal;
				}
				
				else if($1->getMarker() == "CONST_FLOAT" && $3->getMarker() == "CONST_INT") 
				{
					symbol->variables->floatVal = $1->variables->floatVal * $3->variables->intVal;
				}
				
				$$ = symbol;
			
			}

			else if($2->getName() == "%")
			{
				yyerror("Mod cannot be applied on float");
			}
			
			else if($2->getName() == "/")
			{	
				if($1->getMarker() == "CONST_FLOAT" && $3->getMarker() == "CONST_FLOAT")
				{
					if(!$3->variables->floatVal) 
					yyerror("Cannot be divided by zero");
					
					else 
					{
						symbol->variables->floatVal = $1->variables->floatVal / $3->variables->floatVal;
						$$ = symbol;
					}				
				}
				else if($3->getMarker() == "CONST_FLOAT" && $1->getMarker() == "CONST_INT" ) 
				{
					if(!$3->variables->floatVal) 
					yyerror("Cannot be divided by zero");
					else 
					{
						symbol->variables->floatVal = $1->variables->intVal / $3->variables->floatVal;
						$$ = symbol;
					}
				}
				else if( $3->getMarker() == "CONST_INT" && $1->getMarker() == "CONST_FLOAT") 
				{	
					if(!$3->variables->intVal) 
					yyerror("Cannot be divided by zero");
					else
					{
						symbol->variables->floatVal = $1->variables->floatVal / $3->variables->intVal;
						$$ = symbol;
					}
				}
			}
			
			
		
		}
		
		else if($1->getMarker() == "ARRAY")
		{
			if($1->arrays->type == "CONST_INT" && $3->getMarker() == "CONST_INT")
			{
				symbol->setMarker("CONST_INT");
			
				if($2->getName() == "*")
				{
					symbol->variables->intVal = $1->arrays->intArr[globalArrIndex] * $3->variables->intVal;
					$$ = symbol;
				}
			
				else if($2->getName() == "/")
				{
					if(!$3->variables->intVal) 
					yyerror("Can't be divided by zero");
					else 
					{
						symbol->variables->intVal = $1->arrays->intArr[globalArrIndex] / $3->variables->intVal;
						$$ = symbol;
					}
				}
			
				else if($2->getName() == "%")
				{
					if(!$3->variables->intVal) 
					yyerror("Can't be divided by zero");
					else 
					{
						symbol->variables->intVal = $1->arrays->intArr[globalArrIndex] % $3->variables->intVal;
						$$ = symbol;
					}
				}
			}
			
			else if($1->arrays->type == "CONST_FLOAT" || $3->getMarker() == "CONST_FLOAT")
			{
				symbol->setMarker("CONST_FLOAT");
			
				if($2->getName() == "*")
				{
					if($1->arrays->type == "CONST_FLOAT" && $3->getMarker() == "CONST_FLOAT") 
					{
						symbol->variables->floatVal = $1->arrays->floatArr[globalArrIndex] * $3->variables->floatVal;
					}

					else if($1->arrays->type == "CONST_INT" && $3->getMarker() == "CONST_FLOAT") 
					{
						symbol->variables->floatVal = $1->arrays->intArr[globalArrIndex] * $3->variables->floatVal;
					}
			
					else if($1->arrays->type == "CONST_FLOAT" && $3->getMarker() == "CONST_INT") 
					{
						symbol->variables->floatVal = $1->arrays->floatArr[globalArrIndex] * $3->variables->intVal;
					}
			
					
			
					$$ = symbol;
		
				}
		
				else if($2->getName() == "/")
				{	
					if($1->arrays->type == "CONST_FLOAT" && $3->getMarker() == "CONST_FLOAT")
					{
						if(!$2->variables->floatVal)
						yyerror("Can't be divided by zero");
						else 
						{
							symbol->variables->floatVal = $1->arrays->floatArr[globalArrIndex] / $3->variables->floatVal;
							$$ = symbol;
						}				
					}
					else if($1->arrays->type == "CONST_FLOAT" && $3->getMarker() == "CONST_INT") 
					{
						if(!$2->variables->floatVal) 
						yyerror("Can't be divided by zero");
						else 
						{
							symbol->variables->floatVal = $1->arrays->floatArr[globalArrIndex] / $3->variables->intVal;
							$$ = symbol;
						}
					}
					else if($1->arrays->type == "CONST_INT" && $3->getMarker() == "CONST_FLOAT") 
					{	
						if(!$2->variables->intVal) 
						yyerror("Can't be divided by zero");
						else
						{
							symbol->variables->floatVal = $1->arrays->intArr[globalArrIndex] / $3->variables->floatVal;
							$$ = symbol;
						}
					}
				}
		
				else if($2->getName() == "%")
				{
					yyerror("Mod operator can't be applied on float");
				}
				
			}
			
		}

		else if($3->getMarker() == "ARRAY")
		{
			if($3->arrays->type == "CONST_INT" && $1->getMarker() == "CONST_INT")
			{
				symbol->setMarker("CONST_INT");
			
				if($2->getName() == "*")
				{
					symbol->variables->intVal = $3->arrays->intArr[globalArrIndex] * $1->variables->intVal;
					$$ = symbol;
				}
			
				else if($2->getName() == "/")
				{
					if(!$3->arrays->intArr[globalArrIndex]) 
					yyerror("Can't be divided by zero");
					else 
					{
						symbol->variables->intVal = $1->variables->intVal / $3->arrays->intArr[globalArrIndex];
						$$ = symbol;
					}
				}
			
				else if($2->getName() == "%")
				{
					if(!$3->arrays->intArr[globalArrIndex]) yyerror("Can't be divided by zero");
					else 
					{
						symbol->variables->intVal = $1->variables->intVal % $3->arrays->intArr[globalArrIndex];
						$$ = symbol;
					}
				}
			}
			
			else if($3->arrays->type == "CONST_FLOAT" || $1->getMarker() == "CONST_FLOAT")
			{
				symbol->setMarker("CONST_FLOAT");
			
				if($2->getName() == "*")
				{
					if($3->arrays->type == "CONST_FLOAT" && $1->getMarker() == "CONST_FLOAT") 
					symbol->variables->floatVal = $1->variables->floatVal * $3->arrays->floatArr[globalArrIndex];

					else if($3->arrays->type == "CONST_INT" && $1->getMarker() == "CONST_FLOAT") 
					symbol->variables->floatVal = $1->variables->floatVal * $3->arrays->intArr[globalArrIndex];
			
					else if($3->arrays->type == "CONST_FLOAT" && $1->getMarker() == "CONST_INT") 
					symbol->variables->floatVal =  $1->variables->intVal * $3->arrays->floatArr[globalArrIndex];
			
					
			
					$$ = symbol;
		
				}
		
				else if($2->getName() == "/")
				{	
					if($3->arrays->type == "CONST_FLOAT" && $1->getMarker() == "CONST_FLOAT")
					{
						if(!$3->arrays->floatArr[globalArrIndex]) yyerror("Can't be divided by zero");
						else 
						{
							symbol->variables->floatVal = $1->variables->floatVal / $3->arrays->floatArr[globalArrIndex];
							$$ = symbol;
						}				
					}
					
					else if($3->arrays->type == "CONST_FLOAT" && $1->getMarker() == "CONST_INT") 
					{
						if(!$3->arrays->floatArr[globalArrIndex]) 
						yyerror("Can't be divided by zero");
						else 
						{
							symbol->variables->floatVal = $1->variables->intVal / $3->arrays->floatArr[globalArrIndex];
							$$ = symbol;
						}
					}
					else if($3->arrays->type == "CONST_INT" && $1->getMarker() == "CONST_FLOAT") 
					{	
						if(!$3->arrays->intArr[globalArrIndex]) yyerror("Can't be divided by zero");
						else
						{
							symbol->variables->floatVal = $1->variables->floatVal / $3->arrays->intArr[globalArrIndex];
							$$ = symbol;
						}
					}
				}
		
				else if($2->getName() == "%")
				{
					yyerror("Mod operator can't be applied on float");
				}
				
			}
			
		}
		
		else if ($1->getMarker() == "FUNCTION" || $3->getMarker() == "FUNCTION")
		{
			symbol->setMarker("CONST_INT");
			if($2->getName() == "*") 
			{
				symbol->variables->intVal = 0;
				$$ = symbol;
			}
			else if($2->getName() == "/")
			{
				if($3->getMarker() == "FUNCTION") 
				yyerror("Can't be devided by zero");
				else
				{
					symbol->variables->intVal = 0;
					$$= symbol;
				}
			}
			else if($2->getName() == "%")
			{
				if($3->getMarker() == "FUNCTION") yyerror("Can't be devided by zero");
				else
				{
					symbol->variables->intVal = 0;
					$$ = symbol;
				}
			}
		}

	}
	
     ;

unary_expression : ADDOP unary_expression  
{
		printIntoLogFile("unary_expression : ADDOP unary_expression");
		symbolInfo* symbol = new symbolInfo();
		if($2->getMarker() == "CONST_INT")
		{
			symbol->setMarker("CONST_INT");
			if($1->getName() == "+")
			{
				symbol->variables->intVal = $2->variables->intVal;
				$$ = symbol;
			}
			else if($1->getName() == "-")
			{
				symbol->variables->intVal = (-1)*($2->variables->intVal);
				$$ = symbol;
			}
		}
		else if($2->getMarker() == "CONST_FLOAT")
		{
			symbol->setMarker("CONST_FLOAT");
			if($1->getName() == "+")
			{
				symbol->variables->floatVal = $2->variables->floatVal;
				$$ = symbol;
			}
			else if($1->getName() == "-")
			{
				symbol->variables->floatVal = (-1)*($2->variables->floatVal);
				$$ = symbol;
			}
		}
		else if($2->getMarker() == "ARRAY")
		{
			if($2->arrays->type == "CONST_INT")
			{
				symbol->setMarker("CONST_INT");;
				if($1->getName() == "+")
				{
					symbol->variables->intVal = $2->arrays->intArr[globalArrIndex];
					$$ = symbol;
				}
				else if($1->getName() == "-")
				{
					symbol->variables->intVal = (-1)*($2->arrays->intArr[globalArrIndex]);
					$$ = symbol;
				}
			}
			else if($2->arrays->type == "CONST_FLOAT")
			{
				symbol->setMarker("CONST_FLOAT");;
				if($1->getName() == "+")
				{
					symbol->variables->floatVal = $2->arrays->intArr[globalArrIndex];
					$$ = symbol;
				}
				else if($1->getName() == "-")
				{
					symbol->variables->floatVal = (-1)*($2->arrays->floatArr[globalArrIndex]);
					$$ = symbol;
				}
			}
		}
		else if($2->getMarker() == "FUNCTION")
		{
			if($2->functions->type == "CONST_INT")
			{
				symbol->setMarker("CONST_INT");;
				if($1->getName() == "+")
				{
					symbol->variables->intVal = 0;
					$$ = symbol;
				}
				else if($1->getName() == "-")
				{
					symbol->variables->intVal = 0;
					$$ = symbol;
				}
			}
			else if($2->functions->type == "CONST_FLOAT")
			{
				symbol->setMarker("CONST_FLOAT");;
				if($1->getName() == "+")
				{
					symbol->variables->floatVal = 0;
					$$ = symbol;
				}
				else if($1->getName() == "-")
				{
					symbol->variables->floatVal = 0;
					$$ = symbol;
				}
			}			
		}	
	}
		 | NOT unary_expression 
		 {
		printIntoLogFile("unary_expression : NOT unary_expression");
		symbolInfo* symbol = new symbolInfo();
		symbol->setMarker("CONST_INT");
		if($2->getMarker() == "CONST_INT")
		{	
			
			symbol->variables->intVal = !($2->variables->intVal);
			
		}
		else if($2->getMarker() == "CONST_FLOAT")
		{
			symbol->variables->intVal = !($2->variables->floatVal);
		}
		else if($2->getMarker() == "ARRAY")
		{
			if($2->arrays->type == "CONST_INT")
			{
				symbol->variables->intVal = !($2->arrays->intArr[globalArrIndex]);
			}
			else if($2->arrays->type == "CONST_FLOAT")
			{
				symbol->variables->intVal = !($2->arrays->floatArr[globalArrIndex]);
			}
		}
		else if($2->getMarker() == "FUNCTION")
		{
			if($2->functions->type == "CONST_INT")
			{
				symbol->variables->intVal = 0;
			}
			else if($2->functions->type == "CONST_FLOAT")
			{
				symbol->variables->intVal = 0;
			}
		}
		
	}
		 | factor 
		 {
		printIntoLogFile("unary_expression : factor");
		$$ = $1;
	}
		 ;
	
factor	: variable 
{
		printIntoLogFile("factor : variable");
		$$ = $1;
		
	}
	| ID LPAREN argument_list RPAREN
	{ 
		printIntoLogFile("factor	: ID LPAREN argument_list RPAREN");
		symbolInfo* symbol = symTable->lookUp($1->getName(), "FUNCTION");
		bool errorOccurance = false;
		if(!symbol) 
		yyerror("Function non-existant.");
		else
		{
			if(symbol->functions->size != globalParamListSizeImplementing) 
			{
				yyerror("Argument list size mismatch.");
				errorOccurance = true;
			}
			if(globalParamListSizeImplementing > 0)
			{
				for(int i = 0; i < symbol->functions->size; i++)
				{
					if(symbol->functions->list[i] != globalParamListImplementing[i] -> getMarker())
					{
					
						yyerror("Parameter type mismatch");
						errorOccurance = true;
						break;
					}
				}
			}
			if(!errorOccurance)
			{
				$$ = symbol;
			}
			globalParamListSizeImplementing = -1;
		}	
	}
	| LPAREN expression RPAREN
	{ 
		printIntoLogFile("factor : LPAREN expression RPAREN");
		$$ = $2;
	 }
	| CONST_INT 
	{
		printIntoLogFile("factor : CONST_INT");
		symbolInfo* symbol = new symbolInfo();
		symbol->setType("CONST_INT");
		symbol->setMarker("CONST_INT");
		symbol->variables->intVal = atoi($1->getName().c_str());
		$$ = symbol;
		
	}
	| CONST_FLOAT
	{
		printIntoLogFile("factor : CONST_FLOAT");
		symbolInfo* symbol = new symbolInfo();
		symbol->setType("CONST_FLOAT");
		symbol->setMarker("CONST_FLOAT");
		symbol->variables->floatVal = atof($1->getName().c_str());
		$$ = symbol;
	 }
	| variable INCOP 
	{
		printIntoLogFile("factor	: variable INCOP");
		symbolInfo* symbol = new symbolInfo();
		if($1->getMarker() == "CONST_INT")
		{
			$1->variables->intVal = $1->variables->intVal + 1;
			symbol->setMarker("CONST_INT");
			symbol->variables->intVal = $1->variables->intVal;
		}
		else if($1->getMarker() == "CONST_FLOAT")
		{
			$1->variables->floatVal = $1->variables->floatVal + 1;
			symbol->setMarker("CONST_FLOAT");
			symbol->variables->floatVal = $1->variables->floatVal;
		}
		else if($1->getMarker() == "ARRAY")
		{
			if($1->arrays->type == "CONST_INT")
			{
				$1->arrays->intArr[globalArrIndex] = $1->arrays->intArr[globalArrIndex] + 1;
				symbol->setMarker("CONST_INT");
				symbol->variables->intVal = $1->arrays->intArr[globalArrIndex];
			}
			else if($1->arrays->type == "CONST_FLOAT")
			{
				$1->arrays->floatArr[globalArrIndex] = $1->arrays->floatArr[globalArrIndex] + 1;
				symbol->setMarker("CONST_FLOAT");
				symbol->variables->floatVal = $1->arrays->floatArr[globalArrIndex];
			}
		}
	} 
	| variable DECOP
	{ 
		printIntoLogFile("factor	: variable DECOP");
		symbolInfo* symbol = new symbolInfo();

		if($1->getMarker() == "CONST_FLOAT")
		{
			$1->variables->floatVal = $1->variables->floatVal - 1;
			symbol->setMarker("CONST_FLOAT");
			symbol->variables->floatVal = $1->variables->floatVal;
		}
		
		else if($1->getMarker() == "CONST_INT")
		{
			$1->variables->intVal = $1->variables->intVal - 1;
			symbol->setMarker("CONST_INT");
			symbol->variables->intVal = $1->variables->intVal;
		}
		else if($1->getMarker() == "ARRAY")
		{
			if($1->arrays->type == "CONST_INT")
			{
				$1->arrays->intArr[globalArrIndex] = $1->arrays->intArr[globalArrIndex] - 1;
				symbol->setMarker("CONST_INT");
				symbol->variables->intVal = $1->arrays->intArr[globalArrIndex];
			}
			else if($1->arrays->type == "CONST_FLOAT")
			{
				$1->arrays->floatArr[globalArrIndex] = $1->arrays->floatArr[globalArrIndex] - 1;
				symbol->setMarker("CONST_FLOAT");
				symbol->variables->floatVal = $1->arrays->floatArr[globalArrIndex];
			}
		}
	}
	;
	
argument_list : arguments
			{
			 printIntoLogFile("argument_list : arguments");
		    }
			  |
			  {
			  	printIntoLogFile("argument_list : ");
			  }
			  ;
	
arguments : arguments COMMA logic_expression
{
		printIntoLogFile("arguments : arguments COMMA logic_expression");
		symbolInfo* symbol = new symbolInfo();
		symbol->setMarker($3->getMarker());
		if(symbol->getMarker() == "CONST_INT")
		{
			symbol->variables->intVal = $3->variables->intVal;
		}
		else if(symbol->getMarker() == "CONST_FLOAT")
		{
			symbol->variables->floatVal = $3->variables->floatVal;
		}
		else if(symbol->getMarker() == "ARRAY")
		{
			if($3->arrays->type == "CONST_INT")
			{
				symbol->variables->intVal = $3->arrays->intArr[globalArrIndex];
			}
			else if($3->arrays->type == "CONST_FLOAT")
			{
				symbol->variables->floatVal = $3->arrays->floatArr[globalArrIndex];
			}
		}
		else if($3->getMarker() == "FUNCTION")
		{
			if(symbol->functions->type == "CONST_INT")
			{
				symbol->variables->intVal = 0;
			}
			else if(symbol->functions->type == "CONST_FLOAT")
			{
				symbol->variables->intVal = 0;
			}
		}
		globalParamListImplementing[globalParamListSizeImplementing++] = symbol;
	}
	      | logic_expression
	      {
		printIntoLogFile("arguments : logic_expression");

		symbolInfo* symbol = new symbolInfo();
		
		symbol->setMarker($1->getMarker());
		


		if(symbol->getMarker() == "CONST_FLOAT")
		{
			symbol->variables->floatVal = $1->variables->floatVal;
		}

		else if(symbol->getMarker() == "CONST_INT")
		{
			symbol->variables->intVal = $1->variables->intVal;
		}

		else if(symbol->getMarker() == "ARRAY")
		{
			if($1->arrays->type == "CONST_INT")
			{
				symbol->variables->intVal = $1->arrays->intArr[globalArrIndex];
			}
			else if($1->arrays->type == "CONST_FLOAT")
			{
				symbol->variables->floatVal = $1->arrays->floatArr[globalArrIndex];
			}
		}
		else if($1->getMarker() == "FUNCTION")
		{
			if(symbol->functions->type == "CONST_INT")
			{
				symbol->variables->intVal = 0;
			}
			else if(symbol->functions->type == "CONST_FLOAT")
			{
				symbol->variables->intVal = 0;
			}
		}
		globalParamListSizeImplementing = 0;
		globalParamListImplementing[globalParamListSizeImplementing++] = symbol;
		
	}
	
	      ;
 

%%

int main(int argc,char *argv[])
{

	if((fp=fopen(argv[1],"r"))==NULL)
	{
		printf("Cannot Open Input File.\n");
		exit(1);
	}



	

	yyin=fp;

    logout=fopen("1605102_log.txt","w");
  	errorout=fopen("1605102_error.txt","w");
  	symTable->enterScope(logout);
	yyparse();
	endPrint();
	

	fclose(logout);
	fclose(errorout);
	fclose(yyin);
	
	return 0;
}