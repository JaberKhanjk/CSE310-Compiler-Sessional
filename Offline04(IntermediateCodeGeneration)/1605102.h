#include <bits/stdc++.h>
#include<stdio.h>
#include<iostream>
#include<stdlib.h>
#include<iterator>
#include<string>
#include<vector>
#include<fstream>

using namespace std;

class forVariables
{
public:

	int intVal=-99999;
	float  floatVal=-99999.9;
	string name;
	string type;


	forVariables()
	{

	}

	forVariables(string t)
	{
		type=t;
	}

	forVariables(string n, string t)
	{
		name=n;
		type=t;
	}


};

class forArrays
{
public:

	int intArr[100];
	float floatArr[100];
	string type;
	int arrSize;

	forArrays()
	{
        arrSize=0;


	}

	forArrays(string t)
	{
		type=t;
		arrSize=0;
	}


};

class forFunctions
{
public:
	bool declaration;//flag
	bool definition;//flag
	string type;//return type
	int size;//number of parameters
	string list[100];//list of the parameters

	forFunctions()
	{
        size=0;
        definition=false;
        declaration=false;
		


	}
	
	
};



class symbolInfo
{

    string Name;

    string Type;

    string Marker;

    string Address;

    string asmSymbol;


public:
    string Code;
	forVariables *variables;
	forArrays *arrays;
	forFunctions *functions;

    symbolInfo* Next;

    symbolInfo()
    {
        Name = "";
        Type = "";
        Marker = "";
        Code = "";
        Address = "";
        Next=NULL;
        variables=new forVariables();
        arrays=new forArrays();
        functions=new forFunctions();
    }

    symbolInfo(string name, string type)
    {
    	Name=name;
    	Type=type;
        Marker=type;
        Code = "";
        Address = "";
        asmSymbol = "";
    	Next=NULL;
    	variables=new forVariables(Type);
    	functions=new forFunctions();
    }

    symbolInfo(string name,string type,string marker)
    {
        Name=name;
        Type=type;
        Next=NULL;
        Marker=marker;
        Code = "";
        Address = "";
        asmSymbol = "";

        if (marker=="ARRAY")
        {
        	arrays=new forArrays(Type);
        }
        else if (marker=="FUNCTION")
        {
        	functions=new forFunctions();
        	
        }
    }

    string getName()
    {
        return Name;
    }



    void setName(string name)
    {
        Name = name;

    }



    string getType()
    {
        return Type;
    }



    void setType(string type)
    {
        Type = type;

    }


    string getMarker()
    {
    	return Marker;
    }


    void setMarker(string marker)
    {
    	Marker=marker;
    }


    string getCode()
    {
        return Code;
    }


    void setCode(string code)
    {
         Code = code;
    }


    string getAddress()
    {
        return Address;
    }

    void setAddress(string address)
    {
        Address = address;
    }

    symbolInfo* getNext()
    {
        return Next;
    }


    void setNext(symbolInfo* next)
    {
        Next=next;
    }

    string getAsmSymbol()
    {
        return asmSymbol;
    }

    void setAsmSymbol(string sym)
    {
        asmSymbol = sym;
    }


};



class scopeTable
{
public:

    symbolInfo **symbolList;

    scopeTable *parentScope;

    int scopeID;

    int Size=9;

    scopeTable(int id)
    {
        scopeID = id;
        
        symbolList = new symbolInfo*[Size];

        for(int i=0 ; i<Size ; i++)
        {
            symbolList[i] = NULL;

        }

        parentScope = NULL;
    }

    int hashFunction(string word)
    {
        int seed = 131;
        unsigned long hash = 0;

        //cout<<word.length()<<endl;
        for(int i = 0; i < word.length(); i++)
        {
            hash = (hash * seed) + word[i];
        }
        return hash % Size;
    }


    bool insertIntoScopeTable(string sName, string sType, string sMarker)
    {
        int hashValue=hashFunction(sName);
        int pos=0;
        //cout<<hashValue<<endl;

        symbolInfo *test;
        test = symbolList[hashValue];
        if(!test)
        {
            test = new symbolInfo();
            test->setMarker(sMarker);
            test->setType(sType);
            test->setName(sName);
            test->setNext(NULL);
            symbolList[hashValue] = test;
            return true;
        }

        else
        {
            symbolInfo *temp = symbolList[hashValue], *parent = NULL;
            while(temp)
            {
                parent = temp;
                if (temp->getName() == sName && temp->getMarker()==sMarker)
                {
                    return false;
                }
                temp = temp->getNext();
                pos++;
            }
            temp = new symbolInfo();
            temp->setName(sName);
            temp->setType(sType);
            temp->setNext(NULL);
            parent->setNext(temp);

            return true;
            
        }
    }


    bool insertIntoScopeTable(symbolInfo *symbol)
    {
    	string sName = symbol->getName();
        string sType = symbol->getType();
        string sMarker = symbol->getMarker();

        int hash1=hashFunction(sName);
        int pos=0;
        symbolInfo *temp = symbolList[hash1];

        if (!temp)
        {
            temp = symbol;
            symbolList[hash1]=temp;
            return true;
        }
        else
        {
            symbolInfo *temp1=symbolList[hash1], *parent = NULL;
            while(temp1)
                {
                    parent=temp1;
                    if (temp1->getName()==sName && temp1->getMarker()==sMarker)
                    {
                        return false;
                    }
                    temp1 = temp1->getNext();
                    pos++;
                }
                temp1=symbol;
                parent->setNext(temp1);
                return true;
        }
    }






    symbolInfo* lookupInScopeTable(string lName)
    {
        int hash1=hashFunction(lName);
        int pos=0;

        symbolInfo *temp , *parent=NULL;
        temp = symbolList[hash1];
        while (temp)
        {
            parent = temp;
            if (temp->getName() == lName && temp->getMarker()!="ARRAY" && temp->getMarker()!="FUNCTION")
            {
                
               
                return temp ;
            }
           
            temp = temp->getNext() ; 
             pos++;
        }
      
        return NULL ;
    }

    symbolInfo* lookupInScopeTable(string lName,string lMarker)
    {
       int hash1=hashFunction(lName);
        int pos=0;

        symbolInfo *temp , *parent=NULL;
        temp = symbolList[hash1];
        while (temp)
        {
            parent = temp;
            if (temp->getName() == lName && temp->getMarker()==lMarker)
            {
                
               
                return temp ;
            }
           
            temp = temp->getNext() ; 
             pos++;
        }
      
        return NULL ;
    }

    bool deleteFromScopeTable(string dName,string dMarker)
    {

        int hash2 = hashFunction(dName);
        int pos = 0;

        symbolInfo *temp = symbolList[hash2], *parent = NULL;

        if(temp && temp->getName() == dName && temp->getMarker() == dMarker){
            symbolList[hash2] = temp->getNext();
            delete temp;
            return true;
        }

        while(temp)
        {
            if(temp -> getName() == dName && temp->getMarker() == dMarker)
            {
                parent -> setNext(temp -> getNext());
                delete temp;
                return true;
            }
            parent = temp;
            temp = temp -> getNext();
            pos++;

        }

        return false;



        // symbolInfo *looking = lookupInScopeTable(dName,dMarker);
        // int hash2 = hashFunction(dName);

        // symbolInfo *temp, *prev;
        // temp = symbolList[hash2];

        // while (temp != NULL)
        // {
        //     if (temp->getName() == dName && temp->getMarker()== dMarker) break ;
        //     prev = temp;
        //     temp = temp->Next ;
        // }
        // if (temp == NULL)
        // {
        //     cout<<"Symbol not found to delete."<<endl;
        //     return false ;
        // }
        // if (temp == symbolList[hash2]) 
        // {
        //     symbolList[hash2] = symbolList[hash2]->Next ;
        //     delete temp;

        // }
        // else
        // {
        //     prev->Next = temp->Next ;
        //     delete temp;

        // }
        // cout<<"Symbol deleted successfully."<<endl;
        // return true ;
    }


    void printScopetable(FILE *logout)
    {
        //cout<<symbolList[0]->getName()<<","<<symbolList[0]->getType()<<"->";

        fprintf(logout,"Scopetable  #    %d \n",scopeID);
       // cout<<"ScopeTable #"<<scopeID<<endl;
        for(int i=0 ; i<Size ; i++)
        {
            symbolInfo * temp;
            temp = symbolList[i];


            if(temp)
            {
                fprintf(logout,"%d--->",i);
                while(temp)
            {
                //cout<<" < "<<temp->getName()<<" : "<<temp->getType()<<" > ";
                fprintf(logout,"   <  %s , %s , ",temp->getName().c_str(),temp->getType().c_str());
                if (temp->getMarker()=="ARRAY")
                {
                	fprintf(logout, "{ ");
                	for(int j=0 ; j<temp->arrays->arrSize ; j++)
                	{
                		if (temp->arrays->type=="CONST_INT")
                		{
                			fprintf(logout, "%d, ",temp->arrays->intArr[j]);
                		}
                		else if (temp->arrays->type=="CONST_FLOAT")
                		{
                			fprintf(logout, "%f, ",temp->arrays->floatArr[j]);
                		}
                	}  

					fprintf(logout, "}");

                }

                else 
                {
                	if (temp->getMarker()=="CONST_INT")
                	{
                		fprintf(logout, "%d",temp->variables->intVal);
                	}
                	else if (temp->getMarker()=="CONST_FLOAT")
                	{
                		fprintf(logout, "%f",temp->variables->floatVal);
                	}
                	
                }
           		
           		fprintf(logout,">");

                temp = temp->Next;
            }
            fprintf(logout,"\n");

            }
            
            
        }




       
    }

    ~scopeTable()
    {
        Size=0;
        delete symbolList;
    }



};



class symbolTable
{
public:

    scopeTable *current;

   // int numberOfScopes=0;

    int tID=1;

    symbolTable()
    {

        current=NULL;
        
    }

    void enterScope(FILE *logout )
    {
        scopeTable *newScope = new scopeTable(tID++);
        newScope->parentScope=current;
        current=newScope;
        fprintf(logout, "New scope table with id  %d created.\n",tID - 1);
        //cout<<"New scope table with id "<<tID<<" created."<<endl;
       
    }

    void exitScope(FILE *logout)
    {
        scopeTable *temp = current;
        if(temp)
        {
            
            current=temp->parentScope;
            fprintf(logout, "Scope table with id  %d removed.\n",tID - 1);
            //cout<<"Scope table with id "<<tID<<" removed."<<endl;

           
            delete temp;
            

        }
      
    }




    bool insertIntoSymbolTable(string iName, string iType,string iMarker)
    {
        if(current)
        {
          return current->insertIntoScopeTable(iName,iType,iMarker);
        }



    }

    bool insertIntoSymbolTable(symbolInfo *symbol)
    {
    	if (current)
    	{
    		return current->insertIntoScopeTable(symbol);
    	}
    }


    bool deleteFromSymbolTable(string dName,string dMarker)
    {

        if(current)
            return current->deleteFromScopeTable(dName,dMarker);
        


    }



    symbolInfo* lookUp(string symName,string symMarker)
    {
        scopeTable* temp = current;

        while (temp)
        {
            if(temp ->lookupInScopeTable(symName,symMarker))
            {
                return temp ->lookupInScopeTable(symName,symMarker);
            }

            temp = temp ->parentScope;
        }
        
        return NULL;

    }

    symbolInfo* lookUp(string symName)
    {
        scopeTable* temp = current;

        while (temp)
        {
            if(temp ->lookupInScopeTable(symName))
            {
                return temp ->lookupInScopeTable(symName);
            }

            temp = temp ->parentScope;
        }
        
        return NULL;

    }

    void printCurrentScope(FILE *logout)
    {
        if(current)
            current->printScopetable(logout);
    }



    void printAllScopes(FILE *logout)
    {
        scopeTable *temp;
        temp=current;

        if(current)
        {
            while(temp)
            {
                temp->printScopetable(logout);
                temp=temp->parentScope;
            }
        }
    }


};