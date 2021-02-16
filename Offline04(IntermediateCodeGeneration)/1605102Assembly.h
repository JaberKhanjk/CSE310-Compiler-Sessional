#include "1605102.h"


string outdec = "\nOUTDEC PROC\nPUSH DX\nPUSH CX\nPUSH BX\nPUSH AX\nOR AX,AX\nJGE @END_IF1\nPUSH AX\nMOV DL,'-'\nMOV AH,2\nINT 21H\nPOP AX\nNEG AX\n@END_IF1:\nXOR CX,CX\nMOV BX,10D\n@REPEAT1:\nXOR DX,DX\nDIV BX\nPUSH DX\nINC CX\nOR AX,AX\nJNE @REPEAT1\nMOV AH,2\n@PRINT_LOOP:\nPOP DX\nOR DL,30H\nINT 21H\nLOOP @PRINT_LOOP\nPOP AX\nPOP BX\nPOP CX\nPOP DX\nRET\nOUTDEC ENDP\n";


int variables = 0, labels = 0;

string startCode = ".MODEL SMALL\n.STACK 100H\n\n.DATA\n";
string mainCode = ".CODE\n\nMAIN PROC\n\nMOV AX, @DATA\nMOV DS, AX\n\n";
string declarationCode = "";
string assemblyFileCode = "";
string bodyCode = "";
string finalCode = "\n\nMOV AH, 4ch\nINT 21H\nMAIN ENDP\n" + outdec + "\nEND MAIN";

string newLabel()
{
	char *label = new char[8];
	strcpy(label,"L");
	char num[3];
	sprintf(num,"%d",labels);
	labels++;
	strcat(label,num);
	return label;
}

string newTemp()
{
	char *temp = new char[4];
	strcpy(temp, "t");
	char num[3];
	sprintf(num, "%d", variables);
	variables++;
	strcat(temp, num);
	declarationCode += (string)temp + " DW ?\n";
	return temp;
}

void codeGeneratorINCOP(symbolInfo* symbol, string arg)
{
	string code = "";
	
	code += "MOV AX, " + arg + "\nINC AX\nMOV "+ arg + ", AX\n";
	
	symbol-> setAddress(arg);
	
	symbol> setCode(symbol> getCode() + code);
	
	return;
}



void codeGeneratorDECOP(symbolInfo* symbol, string arg)
{
	string code = "";
	
	code += "MOV AX, " + arg + "\nDEC AX\nMOV "+ arg + ", AX\n";
	
	symbol-> setAddress(arg);
	
	symbol-> setCode(symbol-> getCode() + code);
	
	return;
}

void codeGeneratorUNARYADDOPMINUS(symbolInfo* symbol, string arg)
{
	string code = "";
	string temp = newTemp();
	symbol->setAddress(temp);
	code += "MOV AX, " + arg + "\nNEG AX\nMOV " + temp + ", AX\n";
	symbol-> setCode(symbol-> getCode() + code);
}

void codeGeneratorUNARYNOT(symbolInfo* symbol, string arg)
{
	string code = "";
	string temp = newTemp();
	string label = newLabel();
	symbol-> setName(temp);
	symbol->setAddress(temp);
	code += "MOV AX, " + arg + "\nCMP AX, 0\nJE " + label + "\nMOV AX, 1\n" + label + ":\nMOV" + temp + ", AX\n";
	symbol-> setCode(symbol-> getCode() + code);
}

void codeGeneratorMULOPMUL(symbolInfo* symbol, string arg1, string arg2)
{

	string temp = newTemp();
	symbol-> setName(temp);
	symbol-> setAddress(temp);
	
	string code = "";
	
	code += "MOV DX, 0\nMOV AX, " + arg1 + "\nMUL " + arg2 + "\nMOV " + temp + ", AX\n";
	
	symbol-> setCode(symbol-> getCode() + code);
	
	return;
}

void codeGeneratorMULOPDIV(symbolInfo* symbol, string arg1, string arg2)
{
	string temp = newTemp();
	symbol-> setName(temp);
	symbol-> setAddress(temp);
	
	string code = "";
	
	code += "MOV DX, 0\nMOV AX, " + arg1 + "\nDIV " + arg2 + "\nMOV " + temp + ", AX\n";
	
	symbol-> setCode(symbol-> getCode() + code);
	
	return;
}

void codeGeneratorMULOPMOD(symbolInfo* symbol, string arg1, string arg2)
{
	string temp = newTemp();
	symbol-> setName(temp);
	symbol-> setAddress(temp);
	
	string code = "";
	
	code += "MOV DX, 0\nMOV AX, " + arg1 + "\nDIV " + arg2 + "\nMOV " + temp + ", DX\n";
	
	symbol-> setCode(symbol-> getCode() + code);
	
	return;
}

void codeGeneratorADDOPPLUS(symbolInfo* symbol, string arg1, string arg2)
{

	string temp = newTemp();
	symbol-> setName(temp);
	symbol-> setAddress(temp);
	
	string code = "";
	
	code += "MOV AX, " + arg1 + "\nADD AX, " + arg2 + "\nMOV " + temp + ", AX\n";
	
	symbol-> setCode(symbol-> getCode() + code);
	
	return;
}

void codeGeneratorADDOPMINUS(symbolInfo* symbol, string arg1, string arg2)
{

	string temp = newTemp();
	symbol-> setName(temp);
	symbol-> setAddress(temp);
	
	string code = "";
	
	code += "MOV AX, " + arg1 + "\nSUB AX, " + arg2 + "\nMOV " + temp + ", AX\n";
	
	symbol-> setCode(symbol-> getCode() + code);
	
	return;
}

void codeGeneratorRELOPLOGICOP(symbolInfo* symbol, string arg1, string opCode, string arg2)
{
	string code = "";
	string temp = newTemp();
	symbol-> setName(temp);
	symbol-> setAddress(temp);
	string falseCondLabel = newLabel();
	string trueCondLabel = newLabel();

	
	if(opCode == ">")
	{
		code += "MOV AX, " + arg1 + "\nCMP AX, " + arg2 + "\nJG " + trueCondLabel + "\nMOV " + temp + ", 0\nJMP " + falseCondLabel + "\n" + trueCondLabel + ":\nMOV " + temp + ", 1\n" + falseCondLabel + ":\n";
	}

	else if(opCode==">=")
	{
		code += "MOV AX, " + arg1 + "\nCMP AX, " + arg2 + "\nJGE " + trueCondLabel + "\nMOV " + temp + ", 0\nJMP " + falseCondLabel + "\n" + trueCondLabel + ":\nMOV " + temp + ", 1\n" + falseCondLabel + ":\n";
	}

	else if(opCode=="<")
	{
		code += "MOV AX, " + arg1 + "\nCMP AX, " + arg2 + "\nJL " + trueCondLabel + "\nMOV " + temp + ", 0\nJMP " + falseCondLabel + "\n" + trueCondLabel + ":\nMOV " + temp + ", 1\n" + falseCondLabel + ":\n";
	}

	else if(opCode=="!=")
	{
		code += "MOV AX, " + arg1 + "\nCMP AX, " + arg2 + "\nJNE " + trueCondLabel + "\nMOV " + temp + ", 0\nJMP " + falseCondLabel + "\n" + trueCondLabel + ":\nMOV " + temp + ", 1\n" + falseCondLabel + ":\n";
	}	
	
	else if(opCode=="<=")
	{
		code += "MOV AX, " + arg1 + "\nCMP AX, " + arg2 + "\nJLE " + trueCondLabel + "\nMOV " + temp + ", 0\nJMP " + falseCondLabel + "\n" + trueCondLabel + ":\nMOV " + temp + ", 1\n" + falseCondLabel + ":\n";
	}
	
	else if(opCode=="==")
	{
		code += "MOV AX, " + arg1 + "\nCMP AX, " + arg2 + "\nJE " + trueCondLabel + "\nMOV " + temp + ", 0\nJMP " + falseCondLabel + "\n" + trueCondLabel + ":\nMOV " + temp + ", 1\n" + falseCondLabel + ":\n";
	}
	
	else if(opCode=="||")
	{
		code += "MOV AX, " + arg1 + "\nCMP AX, 0\nJNE " + trueCondLabel + "\nMOV AX, " + arg2 + "\nCMP AX, 0\nJNE " + trueCondLabel + "\nMOV " + temp + ", 0\nJMP " + falseCondLabel + "\n" + trueCondLabel + ":\nMOV " + temp + ", 1\n" + falseCondLabel + ":\n";
		
	}
	
	else if(opCode=="&&")
	{
		code += "MOV AX, " + arg1 + "\nCMP AX, 0\nJE " + falseCondLabel + "\nMOV AX, " + arg2 + "\nCMP AX, 0\nJE " + falseCondLabel + "\nMOV " + temp + ", 1\nJMP " + trueCondLabel + "\n" + falseCondLabel + ":\nMOV " + temp + ", 0\n" + trueCondLabel + ":\n";
	}
	

	
	symbol-> setCode(symbol->getCode()+code);

	return;
}



void codeGeneratorASSIGNOP(symbolInfo* symbol, string arg1, string arg2)
{
	symbol-> setAddress(arg1);
	
	string code = "";

	code += "MOV AX, " + arg2 + "\nMOV " + arg1 + ", AX\n";
	
	symbol-> setCode(symbol-> getCode()+code);
	
	return;
}

void codeGeneratorPRINTLN(symbolInfo* symbol, string arg)
{
	string code = "";
	code += "MOV AX, " + arg + "\nCALL OUTDEC\nMOV AH, 2\nMOV DL, 0DH\nINT 21H\nMOV AH, 2\nMOV DL, 0AH\nINT 21H\n";
	symbol-> setCode(symbol->getCode()+code);
	return;
}

void codeGeneratorWHILE(symbolInfo* symbol, symbolInfo* cond, symbolInfo* statement)
{
	string code = "";
	string loopStartLabel = newLabel();
	string loopEndLabel = newLabel();
	
	code += loopStartLabel + ":\n" + cond->getCode() + "\nMOV AX, " + cond->getAddress() + " \nCMP AX, 0\nJE " + loopEndLabel + "\n" + statement->getCode() + "\nJMP " + loopStartLabel + "\n" + loopEndLabel + ":\n";
	
	symbol->setCode(symbol->getCode() + code);
	return;
}
void codeGeneratorFOR(symbolInfo* symbol, symbolInfo* startStatement, symbolInfo* cond, symbolInfo* incrementStatement, symbolInfo* statement)
{
	string code = "";
	string loopStartLabel = newLabel();
	string loopEndLabel = newLabel();
	
	code += startStatement->getCode() + "\n" + loopStartLabel + ":\n" + cond->getCode() + "\nMOV AX, " + cond->getAddress() + " \nCMP AX, 0\nJE " + loopEndLabel + "\n" + statement->getCode() + "\n" + incrementStatement->getCode() + "\n" + "JMP " + loopStartLabel + "\n" + loopEndLabel + ":\n";
	
	symbol->setCode(symbol->getCode() + code);
	return;
}

void codeGeneratorIF(symbolInfo *symbol, symbolInfo *cond, symbolInfo* statement)
{
	string code = "";
	string falseCondLabel = newLabel();
	
	code += cond->getCode() + "\nMOV AX, " + cond->getAddress() + "\nCMP AX, 0\nJE " + falseCondLabel + "\n" + statement->getCode() + "\n" + falseCondLabel + ":\n";
	
	symbol->setCode(symbol->getCode() + code);
	return;
}

void codeGeneratorIFELSE(symbolInfo *symbol, symbolInfo *cond, symbolInfo* statement1, symbolInfo* statement2)
{
	string code = "";
	string falseCondLabel = newLabel();
	string conditionDoneLabel = newLabel();
	
	code += cond->getCode() + "\nMOV AX, " + cond->getAddress() + "\nCMP AX, 0\nJE " + falseCondLabel + "\n" + statement1->getCode() + "\nJMP " + conditionDoneLabel + "\n" + falseCondLabel + ":\n" + statement2->getCode() + "\n" + conditionDoneLabel + ":\n";
	
	symbol->setCode(symbol->getCode() + code);
	return;
}

void codeGeneratorCONST(symbolInfo *symbol, symbolInfo* type)
{
	string temp = newTemp();
	symbol-> setAddress(temp);
	
	string code = "";
	
	code += "MOV AX, " + type->get_Name() + "\nMOV " + temp + ", Ax\n";
	symbol->setCode(code);
}