%{
#include "1605102Assembly.h"

using namespace std;

int yyparse(void);
int yylex(void);
// extern char* yytext;
extern FILE *yyin;
FILE *fp;
FILE *logout;
FILE *errorout;
ofstream codeFile;

symbolTable *symTable = new symbolTable();
symbolInfo *dummy = new symbolInfo("compound_statement", "dummy");
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
		$$ = $1;
		assemblyFileCode += startCode + declarationCode + mainCode + $$->getCode() + finalCode;
		codeFile << assemblyFileCode; 
	}
	;

program : program unit 
	{
		printIntoLogFile("program : program unit");
		$$ = $1; $$->setCode($$->getCode() + $2->getCode());
	}
	| unit
	{
		printIntoLogFile("program : unit");
		$$ = $1;
	}
	;
	
unit : var_declaration
	 {
	 	printIntoLogFile("unit : var_declaration");
	 }
     | func_declaration
     {
     	printIntoLogFile("unit : func_declaration");
     	$$ = $1;
     }
     | func_definition
     {
     	printIntoLogFile("unit : func_definition");
     	$$ = $1;
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
		$$ = dummy;
	}
	| type_specifier ID LPAREN parameter_list RPAREN error { $$ = dummy;}
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
		 $$ = dummy;
	}
	| type_specifier ID LPAREN RPAREN error{ $$ = dummy;}
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
					$$->setCode($$->getCode() + $3->getCode());
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
			$$ = $2;
		}
		|type_specifier declaration_list error{$$=dummy;}
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
					declarationCode += $3->getName() + " DW " + "?\n";
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
 		  		

 		  		declarationCode += $3->getName() + " DW ";
			for(int i = 0; i < symbol->arrays->arrSize - 1; i++)
			{
				declarationCode += "?, ";
			}
			declarationCode += "?\n";
			
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
					declarationCode += $1->getName() + " DW " + "?\n";
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

 		  		declarationCode += $1->getName() + " DW ";
			for(int i = 0; i < symbol->arrays->arrSize - 1; i++)
			{
				declarationCode += "?, ";
			}
			declarationCode += "?\n";

 		  		symTable->insertIntoSymbolTable(symbol);
 		  	}
 		  
 		  }
 		  ;
 		  
statements : statement
		{
			printIntoLogFile("statements : statement");
			if($$->getCode() != $1->getCode()) $$->setCode($$->getCode() + $1->getCode());

		}
	   | statements statement
	   {
	   	printIntoLogFile("statements : statements statement");
	   	cout << endl << "Showing Code Before:" << endl << $$->getCode() << endl << endl;
	   	 if($$->getCode() != $2->getCode())
	   	  $$->setCode($$->getCode() + $2->getCode());
	   	  cout << endl << "Showing Code After:" << endl << $$->getCode() << endl << endl;
	   }
	   ;
	   
statement : var_declaration
			{
				printIntoLogFile("statement : var_declaration");
			}

	  | expression_statement
	  {
	  	printIntoLogFile("statement : expression_statement");
	  	if($$->getCode() != $1->getCode()) 
	  	$$->setCode($$->getCode() + $1->getCode());
	  }

	  | compound_statement
	  {
	  	printIntoLogFile("statement : compound_statement");
	  	 $$->setCode($$->getCode() + $1->getCode());
	  }

	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement
	  {
	  	printIntoLogFile("statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement");
	  	codeGeneratorFOR($$, $3, $4, $5, $7);

	  }

	  | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
	  {
	  	printIntoLogFile("statement : IF LPAREN expression RPAREN statement");
	  	codeGeneratorIF($$, $3, $5);  
	  }

	  | IF LPAREN expression RPAREN statement ELSE statement
	  {
	  	printIntoLogFile("statement : IF LPAREN expression RPAREN statement ELSE statement");
	  	codeGeneratorIFELSE($$, $3, $5, $7);  
	  }

	  | WHILE LPAREN expression RPAREN statement
	  {
	  	printIntoLogFile("statement : WHILE LPAREN expression RPAREN statement");
	  	codeGeneratorWHILE($$, $3, $5);
	  }

	  | PRINTLN LPAREN ID RPAREN SEMICOLON
	  {
	  	printIntoLogFile("statement : PRINTLN LPAREN ID RPAREN SEMICOLON");
	  	 codeGeneratorPRINTLN($$, $3->getName());
	  }

	  | PRINTLN LPAREN ID RPAREN error 
	  { $$ = dummy; }

	  | RETURN expression SEMICOLON
	  {
	  	printIntoLogFile("statement : RETURN expression SEMICOLON");
	  	{ $$ = dummy; }
	  }

	  |RETURN expression error
	  { $$ = dummy; }
	  ;
	  
expression_statement 	: SEMICOLON	
			{
				printIntoLogFile("expression_statement : SEMICOLON");
				{ $$ = dummy; }
			}	

			| expression SEMICOLON 
			{
				printIntoLogFile("expression_statement : expression SEMICOLON");
				if($$->getCode() != $1->getCode()) $$->setCode($$->getCode() + $1->getCode());
			}

			|expression error
			{ $$ = dummy; }

			|error
			{ $$ = dummy; }
			;
	  
variable : ID 		
			{
				printIntoLogFile("variable : ID");
				symbolInfo *symbol = symTable->lookUp($1->getName());
				if (!symbol)
				{
					yyerror("Variable not declared before initialization.");
					$$ = dummy;	
				}
				else if (symbol->getMarker()=="ARRAY")
				{
					yyerror("Variable call does not match.");
					$$ = dummy;	
				}
				else
				{
					$$ = symbol;
					symTable->printAllScopes(logout);
				}
				$$->setAddress(symbol->getName());
		$$->setCode("");
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
	 			$$ = dummy;	
				$$->setCode("");
	 		}

	 		if (globalArrIndex >= symbol->arrays->arrSize || globalArrIndex<0)
	 		{
	 			yyerror("Array index out of bound.");
	 		}
	 		else
	 		{
	 			$$ = symbol;
	 			symTable->printAllScopes(logout);
	 			$$->setCode($3->getCode() + "MOV DI, 0\nMOV BX, " + to_string($3->variables->intVal) + "\nADD BX, BX\nADD DI, BX\n");
	 		}
	 	}
	 }
	 ;
	 
 expression : logic_expression	
 		{
 			printIntoLogFile("expression : logic_expression");
 			if($$->getCode() != $1->getCode())
 			 $$->setCode($$->getCode() + $1->getCode());
 		}
	   | variable ASSIGNOP logic_expression 	
	   {
	   	printIntoLogFile("expression : variable ASSIGNOP logic_expression");
	   	$$->setCode($3->getCode() + $1->getCode());

	   	if ($1->getMarker()=="CONST_INT")
	   	{
	   		if ($3->getMarker()=="CONST_INT")
	   		{
	   			$1->variables->intVal = $3->variables->intVal;
	   			codeGeneratorASSIGNOP($$, $1->getName(), $3->getAddress());
	   		}
	   		else if ($3->getMarker()=="CONST_FLOAT")
	   		{
	   			yyerror("Type casting error in assignment.");
	   		}
	   		else if ($3->getMarker()=="ARRAY" && $3->arrays->type=="CONST_INT")
	   		{
	   			$1->variables->intVal=$3->arrays->intArr[globalArrIndex];
	   			codeGeneratorASSIGNOP($$, $1->getName(), $3->getAddress());
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
	   				codeGeneratorASSIGNOP($$, $1->getName(), $3->getAddress());
	   			}
	   		}
	   	}
	   	else if ($1->getMarker()=="CONST_FLOAT")
	   	{
	   		if ($3->getMarker()=="CONST_INT")
	   		{
	   			$1->variables->floatVal=$3->variables->intVal;
	   			codeGeneratorASSIGNOP($$, $1->getName(), $3->getAddress());
	   		}   		
	   		else if ($3->getMarker()=="CONST_FLOAT")
	   		{
	   			$1->variables->floatVal=$3->variables->floatVal;
	   			codeGeneratorASSIGNOP($$, $1->getName(), $3->getAddress());
	   		}
	   		else if ($3->getMarker()=="ARRAY" && $3->arrays->type == "CONST_FLOAT")
	   		{
	   			$1->variables->floatVal=$3->arrays->floatArr[globalArrIndex];
	   			codeGeneratorASSIGNOP($$, $1->getName(), $3->getAddress());
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
	   				codeGeneratorASSIGNOP($$, $1->getName(), $3->getAddress());
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
	   				codeGeneratorASSIGNOP($$, $1->getName() + "[DI]", $3->getAddress());
	   			}

	   			else if($3->getMarker() == "ARRAY" && $3->arrays->type == "CONST_FLOAT")
	   			{
	   				yyerror("Type casting error in assignment");
	   			}

	   			else if($3->getMarker() == "ARRAY" && $3->arrays->type == "CONST_INT") 
	   				{
	   					$1->variables->intVal = $3->arrays->intArr[globalArrIndex];
	   					codeGeneratorASSIGNOP($$, $1->getName() + "[DI]", $3->getAddress());
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
							codeGeneratorASSIGNOP($$, $1->getName() + "[DI]", $3->getAddress());
						} 
		
				}
	   		}

	   		if($1->arrays->type == "CONST_FLOAT")
			{
			    if($3->getMarker() == "CONST_INT") 
				{
					$1->arrays->floatArr[globalArrIndex] = $3->variables->intVal;
					codeGeneratorASSIGNOP($$, $1->getName() + "[DI]", $3->getAddress());
				}	
		
				else if($3->getMarker() == "CONST_FLOAT") 
				{
					$1->arrays->floatArr[globalArrIndex] = $3->variables->floatVal;
					codeGeneratorASSIGNOP($$, $1->getName() + "[DI]", $3->getAddress());
				} 
				else if($3->getMarker() == "ARRAY" && $3->arrays->type == "CONST_INT") 
				{
					$1->variables->floatVal = $3->arrays->intArr[globalArrIndex];
					codeGeneratorASSIGNOP($$, $1->getName() + "[DI]", $3->getAddress());
				}
		
				else if($3->getMarker() == "ARRAY" && $3->arrays->type == "CONST_FLOAT") 
				{
					$1->arrays->floatArr[globalArrIndex] = $3->arrays->floatArr[globalArrIndex];
					codeGeneratorASSIGNOP($$, $1->getName() + "[DI]", $3->getAddress());
				}
		
				else if($3->getMarker() == "FUNCTION")
				{
						if($3->functions->type == "CONST_FLOAT") 
						{
							$1->variables->intVal = 0;
							codeGeneratorASSIGNOP($$, $1->getName() + "[DI]", $3->getAddress());
						}
			
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
		if($$->getCode() != $1->getCode()) $$->setCode($$->getCode() + $1->getCode());	
	}
		 | rel_expression LOGICOP rel_expression 
	
	{
		printIntoLogFile("logic_expression : rel_expression LOGICOP rel_expression");
		$$->setCode($$->getCode() + $3->getCode()); 
		symbolInfo* symbol = new symbolInfo();
		
		symbol->setMarker("CONST_INT");
		
		if($1->getMarker()=="CONST_INT" && $3->getMarker()=="CONST_INT") 
		{
			symbol->variables->intVal = logicHandler($1->variables->intVal, $3->variables->intVal, $2->getName());
			codeGeneratorRELOPLOGICOP($$, $1->getName(), $2->getName(), $3->getName());
		}
		else if($1->getMarker()=="CONST_FLOAT" && $3->getMarker()=="CONST_INT") 
		{
			symbol->variables->intVal = logicHandler($1->variables->floatVal, $3->variables->intVal, $2->getName());
			codeGeneratorRELOPLOGICOP($$, $1->getName(), $2->getName(), $3->getName());
		}
		else if($1->getMarker()=="CONST_FLOAT" && $3->getMarker()=="CONST_FLOAT") 
		{
			symbol->variables->intVal = logicHandler($1->variables->floatVal, $3->variables->floatVal, $2->getName());
			codeGeneratorRELOPLOGICOP($$, $1->getName(), $2->getName(), $3->getName());
		}

		else if($1->getMarker()=="CONST_INT" && $3->getMarker()=="CONST_FLOAT") 
		{
			symbol->variables->intVal = logicHandler($1->variables->intVal, $3->variables->floatVal, $2->getName());
			codeGeneratorRELOPLOGICOP($$, $1->getName(), $2->getName(), $3->getName());
		}


		
		else if($1->getMarker() == "ARRAY" && $1->arrays->type == "CONST_INT")
		{
			codeGeneratorRELOPLOGICOP($$, $1->getName() + "[DI]", $2->getName(), $3->getName());
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
			codeGeneratorRELOPLOGICOP($$, $1->getName(), $2->getName(), $3->getName() + "[DI]");
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
			codeGeneratorRELOPLOGICOP($$, $1->getName(), $2->getName(), $3->getName());
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
			codeGeneratorRELOPLOGICOP($$, $1->getName(), $2->getName(), $3->getName());
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
 		if($$->getCode() != $1->getCode()) $$->setCode($$->getCode() + $1->getCode());
	}
		| simple_expression RELOP simple_expression	
		{ 
		printIntoLogFile("rel_expression	: simple_expression RELOP simple_expression");
		$$->setCode($1->getCode() + $3->getCode()); 
		
		symbolInfo* symbol = new symbolInfo();
		
		symbol->setMarker("CONST_INT");
		
		if($1->getMarker()=="CONST_INT" && $3->getMarker()=="CONST_INT") 
		{
			symbol->variables->intVal = logicHandler($1->variables->intVal, $3->variables->intVal, $2->getName());
			codeGeneratorRELOPLOGICOP($$, $1->getName(), $2->getName(), $3->getName());
		}
		else if($1->getMarker()=="CONST_FLOAT" && $3->getMarker()=="CONST_FLOAT") 
		{
			symbol->variables->intVal = logicHandler($1->variables->floatVal, $3->variables->floatVal, $2->getName());
			codeGeneratorRELOPLOGICOP($$, $1->getName(), $2->getName(), $3->getName());
		}

		else if($1->getMarker()=="CONST_INT" && $3->getMarker()=="CONST_FLOAT")
		{
			symbol->variables->intVal = logicHandler($1->variables->intVal, $3->variables->floatVal, $2->getName());
			codeGeneratorRELOPLOGICOP($$, $1->getName(), $2->getName(), $3->getName());
		}
		

		else if($1->getMarker()=="CONST_FLOAT" && $3->getMarker()=="CONST_INT") 
		{
			symbol->variables->intVal = logicHandler($1->variables->floatVal, $3->variables->intVal, $2->getName());
			codeGeneratorRELOPLOGICOP($$, $1->getName(), $2->getName(), $3->getName());
		}
		

		else if($1->getMarker() == "ARRAY" && $1->arrays->type == "CONST_INT")
		{
			codeGeneratorRELOPLOGICOP($$, $1->getName() + "[DI]", $2->getName(), $3->getName());
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
			codeGeneratorRELOPLOGICOP($$, $1->getName(), $2->getName(), $3->getName() + "[DI]");
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
			codeGeneratorRELOPLOGICOP($$, $1->getName(), $2->getName(), $3->getName());
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
			codeGeneratorRELOPLOGICOP($$, $1->getName(), $2->getName(), $3->getName());
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
		if($$->getCode() != $1->getCode()) $$->setCode($$->getCode() + $1->getCode());
	}
		  | simple_expression ADDOP term 
		  {
		printIntoLogFile("simple_expression : simple_expression ADDOP term");
		$$->setCode($1->getCode() + $3->getCode()); 
		symbolInfo* symbol = new symbolInfo();
		if( $3->getMarker() == "CONST_INT" && $1->getMarker() == "CONST_INT")
		{
			symbol->setMarker("CONST_INT");
			
			if($2->getName() == "+")
			{
				symbol->variables->intVal = $1->variables->intVal + $3->variables->intVal;
				$$ = symbol;
				codeGeneratorADDOPPLUS($$, $1->getName(), $3->getName());
			}
			
			else if($2->getName() == "-")
			{
				symbol->variables->intVal = $1->variables->intVal - $3->variables->intVal;
				$$ = symbol;
				codeGeneratorADDOPMINUS($$, $1->getName(), $3->getName());
			}
			
		}
		
		else if( $3->getMarker() == "CONST_FLOAT" || $1->getMarker() == "CONST_FLOAT")
		{
			symbol->setMarker("CONST_FLOAT");
			
			if($2->getName() == "+")
			{
				codeGeneratorADDOPPLUS($$, $1->getName(), $3->getName());
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
				codeGeneratorADDOPMINUS($$, $1->getName(), $3->getName());
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
					codeGeneratorADDOPPLUS($$, $1->getName() + "[DI]", $3->getName());
				}
			
				else if($2->getName() == "-")
				{
					symbol->variables->intVal = $1->arrays->intArr[globalArrIndex] - $3->variables->intVal;
					$$ = symbol;
					codeGeneratorADDOPMINUS($$, $1->getName() + "[DI]", $3->getName());
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
					codeGeneratorADDOPPLUS($$, $1->getName(), $3->getName() + "[DI]");
				}
			
				else if($2->getName() == "-")
				{
					symbol->variables->intVal = $3->arrays->intArr[globalArrIndex] - $1->variables->intVal;
					$$ = symbol;
					codeGeneratorADDOPMINUS($$, $1->getName(), $3->getName() + "[DI]");
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
					codeGeneratorADDOPPLUS($$, $1->getName(), $3->getName());
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
					codeGeneratorADDOPMINUS($$, $1->getName(), $3->getName());
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
	 	if($$->getCode() != $1->getCode()) $$->setCode($$->getCode() + $1->getCode());
	}
     |  term MULOP unary_expression
     { 
    	printIntoLogFile("term : term MULOP unary_expression");
    	$$->setCode($1->getCode() + $3->getCode()); 
    	symbolInfo* symbol = new symbolInfo();
		
		if( $3->getMarker() == "CONST_INT" && $1->getMarker() == "CONST_INT")
		{
			symbol->setMarker("CONST_INT");
			
			if($2->getName() == "*")
			{
				symbol->variables->intVal = $1->variables->intVal * $3->variables->intVal;
				$$ = symbol;
				codeGeneratorMULOPMUL($$, $1->get_Address(), $3->get_Address());
			}
			
			else if($2->getName() == "/")
			{
				if(!$3->variables->intVal) {

				yyerror("Cannot be divided by zero");
			$$ = dummy;
				}
				else 
				{
					symbol->variables->intVal = $1->variables->intVal / $3->variables->intVal;
					$$ = symbol;
					codeGeneratorMULOPDIV($$, $1->get_Address(), $3->get_Address());
				}
			}
			
			else if($2->getName() == "%")
			{
				if(!$3->variables->intVal) {
				yyerror("Cannot be divided by zero");
			$$ = dummy;}
				else 
				{
				
					symbol->variables->intVal = $1->variables->intVal % $3->variables->intVal;
					$$ = symbol;
					codeGeneratorMULOPMOD($$, $1->get_Address(), $3->get_Address());
				}
			}
		}
		
		else if($1->getMarker() == "CONST_FLOAT" || $3->getMarker() == "CONST_FLOAT")
		{
			symbol->setMarker("CONST_FLOAT");
			
			if($2->getName() == "*")
			{
				codeGeneratorMULOPMUL($$, $1->get_Address(), $3->get_Address());
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
		$$->setCode($$->getCode() + $2->getCode());
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
				codeGeneratorUNARYADDOPMINUS($$, $$->get_Address());
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
				codeGeneratorUNARYADDOPMINUS($$, $$->get_Address());
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
					codeGeneratorUNARYADDOPMINUS($$, $$->getName() + "[DI]");
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
					codeGeneratorUNARYADDOPMINUS($$, $$->getName() + "[DI]");
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
					codeGeneratorUNARYADDOPMINUS($$, $$->get_Address());
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
					codeGeneratorUNARYADDOPMINUS($$, $$->get_Address());
				}
			}			
		}	
	}
		 | NOT unary_expression 
		 {
		printIntoLogFile("unary_expression : NOT unary_expression");
		$$->setCode($$->getCode() + $2->getCode());
		symbolInfo* symbol = new symbolInfo();
		symbol->setMarker("CONST_INT");
		if($2->getMarker() == "CONST_INT")
		{	
			
			symbol->variables->intVal = !($2->variables->intVal);
			codeGeneratorUNARYNOT($$, $$->get_Address());
			
		}
		else if($2->getMarker() == "CONST_FLOAT")
		{
			symbol->variables->intVal = !($2->variables->floatVal);
			codeGeneratorUNARYNOT($$, $$->get_Address());
		}
		else if($2->getMarker() == "ARRAY")
		{
			if($2->arrays->type == "CONST_INT")
			{
				symbol->variables->intVal = !($2->arrays->intArr[globalArrIndex]);
				codeGeneratorUNARYNOT($$, $$->getName() + "[DI]");
			}
			else if($2->arrays->type == "CONST_FLOAT")
			{
				symbol->variables->intVal = !($2->arrays->floatArr[globalArrIndex]);
				codeGeneratorUNARYNOT($$, $$->getName() + "[DI]");
			}
		}
		else if($2->getMarker() == "FUNCTION")
		{
			if($2->functions->type == "CONST_INT")
			{
				symbol->variables->intVal = 0;
				codeGeneratorUNARYNOT($$, $$->get_Address());
			}
			else if($2->functions->type == "CONST_FLOAT")
			{
				symbol->variables->intVal = 0;
				codeGeneratorUNARYNOT($$, $$->get_Address());
			}
		}
		
	}
		 | factor 
		 {
		printIntoLogFile("unary_expression : factor");
		string temp = $$->getCode() + $1->getCode();
		$$ = $1;
		$$->setCode(temp);
	}
		 ;
	
factor	: variable 
{
		printIntoLogFile("factor : variable");
		string temp = $$->getCode() + $1->getCode();
		$$ = $1;
		$$->setCode(temp);
		
	}
	| ID LPAREN argument_list RPAREN
	{ 
		//printIntoLogFile("factor	: ID LPAREN argument_list RPAREN");
		symbolInfo* symbol = symTable->lookUp($1->getName(), "FUNCTION");
		bool errorOccurance = false;
		if(!symbol) 
		{
			yyerror("Function non-existant.");
			$$=dummy;
			errorOccurance=true;
		}
		else
		{
			if(symbol->functions->size != globalParamListSizeImplementing) 
			{
				yyerror("Argument list size mismatch.");
				$$ = dummy;
				errorOccurance = true;
			}
			if(globalParamListSizeImplementing > 0)
			{
				for(int i = 0; i < symbol->functions->size; i++)
				{
					if(symbol->functions->list[i] != globalParamListImplementing[i] -> getMarker())
					{
					
						yyerror("Parameter type mismatch");
						$$ = dummy;
						errorOccurance = true;
						break;
					}
				}
			}
			if(!errorOccurance)
			{
				//$$ = symbol;
				$$ = dummy;
			}
			globalParamListSizeImplementing = -1;
		}	
	}
	| LPAREN expression RPAREN
	{ 
		printIntoLogFile("factor : LPAREN expression RPAREN");
		string temp = $$->getCode() + $2->getCode();
		$$ = $2;
		$$->setCode(temp);
	 }
	| CONST_INT 
	{
		printIntoLogFile("factor : CONST_INT");
		symbolInfo* symbol = new symbolInfo();
		symbol->setType("CONST_INT");
		symbol->setMarker("CONST_INT");
		symbol->variables->intVal = atoi($1->getName().c_str());
		$$ = $1;
		codeGeneratorCONST($$, $1);
		
	}
	| CONST_FLOAT
	{
		printIntoLogFile("factor : CONST_FLOAT");
		symbolInfo* symbol = new symbolInfo();
		symbol->setType("CONST_FLOAT");
		symbol->setMarker("CONST_FLOAT");
		symbol->variables->floatVal = atof($1->getName().c_str());
		$$ = $1;
		codeGeneratorCONST($$, $1);
	 }
	| variable INCOP 
	{
		printIntoLogFile("factor	: variable INCOP");
		symbolInfo* symbol = new symbolInfo();
		string temp = $$->getCode() + $1->getCode();
		$$ = $1;
		$$->setCode(temp);
		if($1->getMarker() == "CONST_INT")
		{
			$1->variables->intVal = $1->variables->intVal + 1;
			symbol->setMarker("CONST_INT");
			symbol->variables->intVal = $1->variables->intVal;
			codeGeneratorINCOP($$, $1->getName());
		}
		else if($1->getMarker() == "CONST_FLOAT")
		{
			$1->variables->floatVal = $1->variables->floatVal + 1;
			symbol->setMarker("CONST_FLOAT");
			symbol->variables->floatVal = $1->variables->floatVal;
			codeGeneratorINCOP($$, $1->getName());
		}
		else if($1->getMarker() == "ARRAY")
		{
			if($1->arrays->type == "CONST_INT")
			{
				$1->arrays->intArr[globalArrIndex] = $1->arrays->intArr[globalArrIndex] + 1;
				symbol->setMarker("CONST_INT");
				symbol->variables->intVal = $1->arrays->intArr[globalArrIndex];
				codeGeneratorINCOP($$, $$->getName() + "[DI]");
			}
			else if($1->arrays->type == "CONST_FLOAT")
			{
				$1->arrays->floatArr[globalArrIndex] = $1->arrays->floatArr[globalArrIndex] + 1;
				symbol->setMarker("CONST_FLOAT");
				symbol->variables->floatVal = $1->arrays->floatArr[globalArrIndex];

				codeGeneratorINCOP($$, $$->getName() + "[DI]");
			}
		}
	} 
	| variable DECOP
	{ 
		printIntoLogFile("factor	: variable DECOP");
		string temp = $$->getCode() + $1->getCode();
		$$ = $1;
		$$->setCode(temp);
		symbolInfo* symbol = new symbolInfo();

		if($1->getMarker() == "CONST_FLOAT")
		{
			$1->variables->floatVal = $1->variables->floatVal - 1;
			symbol->setMarker("CONST_FLOAT");
			symbol->variables->floatVal = $1->variables->floatVal;
			codeGeneratorDECOP($$, $1->getName());
		}
		
		else if($1->getMarker() == "CONST_INT")
		{
			$1->variables->intVal = $1->variables->intVal - 1;
			symbol->setMarker("CONST_INT");
			symbol->variables->intVal = $1->variables->intVal;
			codeGeneratorDECOP($$, $1->getName());
		}
		else if($1->getMarker() == "ARRAY")
		{
			if($1->arrays->type == "CONST_INT")
			{
				$1->arrays->intArr[globalArrIndex] = $1->arrays->intArr[globalArrIndex] - 1;
				symbol->setMarker("CONST_INT");
				symbol->variables->intVal = $1->arrays->intArr[globalArrIndex];
				codeGeneratorDECOP($$, $$->getName() + "[DI]");
			}
			else if($1->arrays->type == "CONST_FLOAT")
			{
				$1->arrays->floatArr[globalArrIndex] = $1->arrays->floatArr[globalArrIndex] - 1;
				symbol->setMarker("CONST_FLOAT");
				symbol->variables->floatVal = $1->arrays->floatArr[globalArrIndex];
				codeGeneratorDECOP($$, $$->getName() + "[DI]");
			}
		}
	}
	;
	
argument_list : arguments
			{
			 printIntoLogFile("argument_list : arguments");
			 
			 $$->Code=$1->Code;
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



        $$->Code=$1->Code+$3->Code;
		  	
		  	$$->Code+="mov ax, "+$3->getAsmSymbol()+"\n";
		  	
		  	$$->Code+="push ax\n";

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

		$$->Code=$1->Code;
		  	
		  	$$->Code+="mov ax, "+$1->getAsmSymbol()+"\n";
		  	$$->Code+="push ax\n";
		
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
  	codeFile.open("code.asm");
  	symTable->enterScope(logout);
	yyparse();
	endPrint();
	

	fclose(logout);
	fclose(errorout);
	fclose(yyin);
	
	return 0;
}