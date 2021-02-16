%option noyywrap

%{
#include<stdio.h>
#include<iostream>
#include<stdlib.h>
#include<iterator>
#include<string>
#include<vector>
#include<fstream>

using namespace std;

int line_count=1;
int error_count=0;
string copyComment;
//string tempstr;
int commentLine = 0;

  int num,r,digit=0,count,pcount=0,i;
    char a[20];

FILE *logout;
FILE *tokenout;




using namespace std;

class symbolInfo
{

    string Name;

    string Type;


public:

    symbolInfo* Next;

    symbolInfo()
    {
        Next=0;
    }

    symbolInfo(string name,string type)
    {
        Name=name;
        Type=type;
        Next=0;
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

    symbolInfo* getNext()
    {
        return Next;
    }

    void setNext(symbolInfo* next)
    {
        Next=next;
    }


};



class scopeTable
{
public:

    symbolInfo **symbolList;

    scopeTable *parentScope;

    int scopeID;

    int Size;

    scopeTable(int id, int size)
    {
        scopeID = id;
        Size = size;
        symbolList = new symbolInfo*[Size];

        for(int i=0 ; i<Size ; i++)
        {
            symbolList[i] = 0;

        }

        parentScope = 0;
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


    bool insertIntoScopeTable(string sName, string sType)
    {
        int hashValue=hashFunction(sName);
        int pos=0;
        //cout<<hashValue<<endl;

        symbolInfo *test;
        test = lookupInScopeTable(sName);
        if(test == 0)


        {
            //cout<<"not present already"<<endl;
            symbolInfo *newNode = new symbolInfo(sName,sType);

            symbolInfo *temp;

            temp=symbolList[hashValue];

            if(temp==0)
            {
                symbolList[hashValue] = newNode;
               


                return true;
            }

            while(temp->Next!=0)
            {
                pos++;

                temp=temp->Next;

            }
            pos++;
            temp->Next=newNode;
          


            return true;

        }

        else
        {
            
            return false;
        }
    }






    symbolInfo* lookupInScopeTable(string lName)
    {
        int hash1=hashFunction(lName);
        int pos=0;

        symbolInfo *temp;
        temp = symbolList[hash1];
        while (temp != 0)
        {
            if (temp->getName() == lName)
            {
                
               
                return temp ;
            }
            pos++;
            temp = temp->Next ; 
        }
      
        return 0 ;
    }

    bool deleteFromScopeTable(string dName)
    {
        symbolInfo *looking = lookupInScopeTable(dName);
        int hash2 = hashFunction(dName);

        symbolInfo *temp, *prev;
        temp = symbolList[hash2];

        while (temp != 0)
        {
            if (temp->getName() == dName) break ;
            prev = temp;
            temp = temp->Next ;
        }
        if (temp == 0)
        {
            cout<<"Symbol not found to delete."<<endl;
            return false ;
        }
        if (temp == symbolList[hash2]) 
        {
            symbolList[hash2] = symbolList[hash2]->Next ;
            delete temp;

        }
        else
        {
            prev->Next = temp->Next ;
            delete temp;

        }
        cout<<"Symbol deleted successfully."<<endl;
        return true ;
    }


    void printScopetable()
    {
        //cout<<symbolList[0]->getName()<<","<<symbolList[0]->getType()<<"->";

        fprintf(logout,"Scopetable  #    %d \n",scopeID);
       // cout<<"ScopeTable #"<<scopeID<<endl;
        for(int i=0 ; i<Size ; i++)
        {
            symbolInfo * temp;
            temp = symbolList[i];


            if(temp!=NULL)
            {
                fprintf(logout,"%d--->",i);
                while(temp!=0)
            {
                //cout<<" < "<<temp->getName()<<" : "<<temp->getType()<<" > ";
                fprintf(logout,"   <  %s : %s>",temp->getName().c_str(),temp->getType().c_str());

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

    int numberOfScopes=0;

    int S;

    symbolTable(int size)
    {

        current=0;
        S=size;
    }

    bool enterScope()
    {
        scopeTable *newScope = new scopeTable(++numberOfScopes,S);
        newScope->parentScope=current;
        current=newScope;

        cout<<"New scope table with id "<<numberOfScopes<<" created."<<endl;
        return true;

    }

    bool exitScope()
    {
        if(current!=0)
        {
            scopeTable *temp;
            temp= current;
            current=temp->parentScope;
            cout<<"New scope table with id "<<numberOfScopes<<" removed."<<endl;

            numberOfScopes--;
            delete temp;
            return true;
        }
        else
        {
            cout<<"No scope to exit."<<endl;

        }
    }




    bool insertIntoSymbolTale(string iName, string iType)
    {
        if(current!=0)
        {
            if(current->insertIntoScopeTable(iName,iType))
            {
                return true;
            }
            else return false;

        }

        else
        {
            enterScope();
            if(current->insertIntoScopeTable(iName,iType))
            {
                return true;
            }
            else return false;

        }


    }


    bool deleteFromSymbolTale(string dName)
    {

        if(current!=0)
        {
            if(current->deleteFromScopeTable(dName))
            {
                return true;
            }
            else return false;

        }

        else return false;
    }



    symbolInfo* lookUp(string symName)
    {
        scopeTable *temp;
        temp=current;

        if(current==0)
        {
            cout<<"No scope exists."<<endl;
            return 0;
        }

        while(temp!=0)
        {
            symbolInfo *temp1;
            temp1=temp->lookupInScopeTable(symName);
            if(temp1!=0)
                return temp1;
            else temp=temp->parentScope;
        }
        return 0;

    }

    void printCurrentScope()
    {
        current->printScopetable();
    }



    void printAllScopes()
    {
        scopeTable *temp;
        temp=current;

        if(current!=0)
        {
            while(temp!=0)
            {
                temp->printScopetable();
                temp=temp->parentScope;
            }
        }
    }


};
symbolTable st(10);

%}


WHITESPACE [ \t\f\r\v]+ 

LETTER [a-zA-Z]

DIGIT [0-9]
FLOATLITERAL {DIGIT}*(\.{DIGIT}+)?(E[+-]?{DIGIT}+)?
HDIGIT [0-9A-F]
HEX [0][xX]{HDIGIT}*(\.{HDIGIT}+)?(P[+-]?{DIGIT}+)?

IDENTIFIER [a-zA-Z_][a-zA-Z0-9_]*


STRING ["]([^"\\\n]|\\.|\\\n)*["]
UNFINISHED_STRING ["]([^"\\\n]|\\.|\\\n)*

%x COMMENT
%x MULTI_LINE_COMMENT    


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

"if"    {
            fprintf(tokenout,"<IF>");
            fprintf(logout,"Line no %d: TOKEN <IF> Lexeme %s found\n",line_count,yytext);
        }

"else"  {
            fprintf(tokenout,"<ELSE>");
            fprintf(logout,"Line no %d: TOKEN <ELSE> Lexeme %s found\n",line_count,yytext);
        }


"for"   { 
            fprintf(tokenout,"<FOR>");
            fprintf(logout,"Line no %d: TOKEN <FOR> Lexeme %s found\n",line_count,yytext);

        }
"while"   { 
            fprintf(tokenout,"<WHILE");
            fprintf(logout,"Line no %d: TOKEN <WHILE> Lexeme %s found\n",line_count,yytext);

        }


"do"    {
             fprintf(tokenout,"<DO>");
            fprintf(logout,"Line no %d: TOKEN <DO> Lexeme %s found\n",line_count,yytext);


        } 
"break"   { 
            fprintf(tokenout,"<BREAK>");
            fprintf(logout,"Line no %d: TOKEN <BREAK> Lexeme %s found\n",line_count,yytext);

        }   

"int"  {
              fprintf(tokenout,"<INT>");
            fprintf(logout,"Line no %d: TOKEN <INT> Lexeme %s found\n",line_count,yytext);

        }
"char"   { 
            fprintf(tokenout,"<CHAR>");
            fprintf(logout,"Line no %d: TOKEN <CHAR> Lexeme %s found\n",line_count,yytext);

        }
"float"   { 
            fprintf(tokenout,"<FLOAT>");
            fprintf(logout,"Line no %d: TOKEN <FLOAT> Lexeme %s found\n",line_count,yytext);

        }

"double"   { 
            fprintf(tokenout,"<DOUBLE>");
            fprintf(logout,"Line no %d: TOKEN <DOUBLE> Lexeme %s found\n",line_count,yytext);

        }

"void"   { 
            fprintf(tokenout,"<VOID>");
            fprintf(logout,"Line no %d: TOKEN <VOID> Lexeme %s found\n",line_count,yytext);

        }
"return"   { 
            fprintf(tokenout,"<RETURN>");
            fprintf(logout,"Line no %d: TOKEN <RETURN> Lexeme %s found\n",line_count,yytext);

        }
"switch"   { 
            fprintf(tokenout,"<SWITCH>");
            fprintf(logout,"Line no %d: TOKEN <SWITCH> Lexeme %s found\n",line_count,yytext);

        }        
"case"   { 
            fprintf(tokenout,"<CASE>");
            fprintf(logout,"Line no %d: TOKEN <CASE> Lexeme %s found\n",line_count,yytext);

        }
"default"   { 
            fprintf(tokenout,"<DEFAULT>");
            fprintf(logout,"Line no %d: TOKEN <DEFAULT> Lexeme %s found\n",line_count,yytext);

        }
"continue"  {
              fprintf(tokenout,"<CONTINUE>");
            fprintf(logout,"Line no %d: TOKEN <CONTINUE> Lexeme %s found\n",line_count,yytext);

        } 








"+"     |

"-"     {
            fprintf(tokenout,"<ADDOP,%s>",yytext);
            fprintf(logout,"Line no %d: TOKEN <ADDOP> Lexeme %s found\n",line_count,yytext);
            //st.insertIntoSymbolTale(string(yytext),"ADDOP");
           // st.printCurrentScope();
        }




"*" | 
"/" | 
"%" {
                fprintf(tokenout,"<MULOP,%s>",yytext);
                fprintf(logout,"Line no %d: TOKEN <MULOP> Lexeme %s found\n",line_count,yytext);
            //    st.insertIntoSymbolTale(string(yytext),"MULOP");
            //    st.printCurrentScope();
                

            }


"++" | 
"--" {
                fprintf(tokenout,"<INCOP,%s>",yytext);
                
                fprintf(logout,"Line no %d: TOKEN <INCOP> Lexeme %s found\n",line_count,yytext);
            //    st.insertIntoSymbolTale(string(yytext),"INCOP");
             //   st.printCurrentScope();
                            
     }


"<"  |
"<=" |
">"  |
">=" |
"==" |
"!="     {
                fprintf(tokenout,"<RELOP,%s>",yytext);
                fprintf(logout,"Line no %d: TOKEN <RELOP> Lexeme %s found\n",line_count,yytext);
               // st.insertIntoSymbolTale(string(yytext),"RELOP");
              //  st.printCurrentScope();
            } 



"="      {
                
               fprintf(tokenout,"<ASSIGNOP,%s>",yytext);
                
               fprintf(logout,"Line no %d: TOKEN <ASSIGNOP> Lexeme %s found\n",line_count,yytext);
              // st.insertIntoSymbolTale(string(yytext),"ASSIGNOP");
             //  st.printCurrentScope();
                

            
        }

"&&" | 
"||" {
               fprintf(tokenout,"<LOGICOP,%s>",yytext);
               fprintf(logout,"Line no %d: TOKEN <LOGICOP> Lexeme %s found\n",line_count,yytext);
              // st.insertIntoSymbolTale(string(yytext),"LOGICOP");
             //  st.printCurrentScope();
                
        
      }




"&"  | 
"|"  | 
"^"  |
"<<" | 
">>"      {
                
            fprintf(tokenout,"<BITOP,%s>",yytext);
                
       fprintf(logout,"Line no %d: TOKEN <BITOP> Lexeme %s found\n",line_count,yytext);
      // st.insertIntoSymbolTale(string(yytext),"BITOP");
        //st.printCurrentScope();
                

            
       }


"!" {
                
     fprintf(tokenout,"<NOT,%s>",yytext);
     fprintf(logout,"Line no %d: TOKEN <NOT> Lexeme %s found\n",line_count,yytext);
    // st.insertIntoSymbolTale(string(yytext),"NOT");
    // st.printCurrentScope();
            
}




"(" {
                
      fprintf(tokenout,"<LPAREN,%s>",yytext);
                
      fprintf(logout,"Line no %d: TOKEN <LPAREN> Lexeme %s found\n",line_count,yytext);
     // st.insertIntoSymbolTale(string(yytext),"LPAREN");
     // st.printCurrentScope();
            
    }



")" {
                
     fprintf(tokenout,"<RPAREN,%s>",yytext);
                
     fprintf(logout,"Line no %d: TOKEN <RPAREN> Lexeme %s found\n",line_count,yytext);
     //st.insertIntoSymbolTale(string(yytext),"RPAREN");
    // st.printCurrentScope();

    }




"{" {
                
    fprintf(tokenout,"<LCURL,%s>",yytext);
                
    fprintf(logout,"Line no %d: TOKEN <LCURL> Lexeme %s found\n",line_count,yytext);
                
   // st.insertIntoSymbolTale(string(yytext),"LCURL");
   // st.printCurrentScope();
            
    }



"}" {
                
     fprintf(tokenout,"<RCURL,%s>",yytext);
                
     fprintf(logout,"Line no %d: TOKEN <RCURL> Lexeme %s found\n",line_count,yytext);
    // st.insertIntoSymbolTale(string(yytext),"RCURL");
    // st.printCurrentScope();
            
    }




"[" {
                      
      fprintf(tokenout,"<LTHIRD,%s>",yytext);
                
      fprintf(logout,"Line no %d: TOKEN <LTHIRD> Lexeme %s found\n",line_count,yytext);
     // st.insertIntoSymbolTale(string(yytext),"LTHIRD");
    //  st.printCurrentScope();
            
    }






"]" {
                
      fprintf(tokenout,"<RTHIRD,%s>",yytext);
      fprintf(logout,"Line no %d: TOKEN <RTHIRD> Lexeme %s found\n",line_count,yytext);
     // st.insertIntoSymbolTale(string(yytext),"RTHIRD");
     // st.printCurrentScope();
            
    }




"," {
                
    fprintf(tokenout,"<COMMA,%s>",yytext);
    fprintf(logout,"Line no %d: TOKEN <COMMA> Lexeme %s found\n",line_count,yytext);
   // st.insertIntoSymbolTale(string(yytext),"COMMA");
   // st.printCurrentScope();
            
    }



";" {
                
     fprintf(tokenout,"<SEMICOLON,%s>",yytext);
     fprintf(logout,"Line no %d: TOKEN <SEMICOLON> Lexeme %s found\n",line_count,yytext);
    // st.insertIntoSymbolTale(string(yytext),"SEMICOLON");
     //st.printCurrentScope();
            
}







        
{DIGIT}+    {
                fprintf(tokenout,"<CONST_INT,%s>",yytext);
                fprintf(logout,"Line no %d: TOKEN <CONST_INT> Lexeme %s found\n",line_count,yytext);
                st.insertIntoSymbolTale(string(yytext),"CONST_INT");
                st.printCurrentScope();
            }


{FLOATLITERAL}   {

                fprintf(tokenout,"<CONST_FLOAT,%s>",yytext);
                fprintf(logout,"Line no %d: TOKEN <CONST_FLOAT> Lexeme %s found\n",line_count,yytext);
                st.insertIntoSymbolTale(string(yytext),"CONST_FLOAT");
                st.printCurrentScope();



                 }       
\'\\n\' {
           fprintf(logout,"Line no %d: TOKEN <CONST_CHAR> Lexeme \'\\n\' found\n",line_count);
           char c = '\n';
           fprintf(tokenout,"<CONST_CHAR,%c>",c);
           st.insertIntoSymbolTale(string(yytext),"CONST_CHAR");
           st.printCurrentScope();
        }




\'\\t\' {
          fprintf(logout,"Line no %d: TOKEN <CONST_CHAR> Lexeme \'\\t\' found\n",line_count);
          char c = '\t';
          fprintf(tokenout,"<CONST_CHAR,%c>",c);
          st.insertIntoSymbolTale(string(yytext),"CONST_CHAR");
          st.printCurrentScope();
        }




\'\\a\' {
         fprintf(logout,"Line no %d: TOKEN <CONST_CHAR> Lexeme \'\\a\' found\n",line_count);
         char c = '\a';
         fprintf(tokenout,"<CONST_CHAR,%c>",c);
         st.insertIntoSymbolTale(string(yytext),"CONST_CHAR");
         st.printCurrentScope();
        }





\'\\b\' {
         fprintf(logout,"Line no %d: TOKEN <CONST_CHAR> Lexeme \'\\b\' found\n",line_count);
         char c = '\b';
         fprintf(tokenout,"<CONST_CHAR,%c>",c);
         st.insertIntoSymbolTale(string(yytext),"CONST_CHAR");
         st.printCurrentScope();

        }



\'\\f\' {

         fprintf(logout,"Line no %d: TOKEN <CONST_CHAR> Lexeme \'\\f\' found\n",line_count);
         char c = '\f';
         fprintf(tokenout,"<CONST_CHAR,%c>",c);
         st.insertIntoSymbolTale(string(yytext),"CONST_CHAR");
         st.printCurrentScope();
          
        }




\'\\r\' {
             fprintf(logout,"Line no %d: TOKEN <CONST_CHAR> Lexeme \'\\r\' found\n",line_count);
             char c = '\r';
             fprintf(tokenout,"<CONST_CHAR,%c>",c);
             st.insertIntoSymbolTale(string(yytext),"CONST_CHAR");
             st.printCurrentScope();
            
        }





\'\\v\' {
          fprintf(logout,"Line no %d: TOKEN <CONST_CHAR> Lexeme \'\\v\' found\n",line_count);
          char c = '\v';
          fprintf(tokenout,"<CONST_CHAR,%c>",c);
          st.insertIntoSymbolTale(string(yytext),"CONST_CHAR");
          st.printCurrentScope();
        }



\'\\\"\' {
         fprintf(logout,"Line no %d: TOKEN <CONST_CHAR> Lexeme \'\\\"\' found\n",line_count);
         char c = '\"';
         fprintf(tokenout,"<CONST_CHAR,%c>",c);
         st.insertIntoSymbolTale(string(yytext),"CONST_CHAR");
         st.printCurrentScope();
         }




\'\\\\\' {
           fprintf(logout,"Line no %d: TOKEN <CONST_CHAR> Lexeme \'\\\\\' found\n",line_count);
           char c = '\\';
           fprintf(tokenout,"<CONST_CHAR,%c>",c);
           st.insertIntoSymbolTale(string(yytext),"CONST_CHAR");
           st.printCurrentScope();
        }



\'\\0\' {
         fprintf(logout,"Line no %d: TOKEN <CONST_CHAR> Lexeme \'\\0\' found\n",line_count);
         char c = '\0';
         fprintf(tokenout,"<CONST_CHAR,%c>",c);
         st.insertIntoSymbolTale(string(yytext),"CONST_CHAR");
         st.printCurrentScope();
       }



\'\\\' {
        fprintf(logout,"Error at Line no %d: UNFINISHED CHARACTER %s \n",line_count,yytext);
        error_count++;
       }




'.'    {
         char c = yytext[1];
         fprintf(logout,"Line no %d: TOKEN <CONST_CHAR> Lexeme \'%c\' found\n",line_count,c);
         fprintf(tokenout,"<CONST_CHAR,%c>",c);
         st.insertIntoSymbolTale(string(yytext),"CONST_CHAR");
         st.printCurrentScope();
        
        }




{IDENTIFIER} {
                
             fprintf(tokenout,"<ID,%s>",yytext);
                
             fprintf(logout,"Line no %d: TOKEN <ID> Lexeme %s found\n",line_count,yytext);
             st.insertIntoSymbolTale(yytext,"ID");
             st.printCurrentScope();
            
            }


{STRING}   {
    int line_no = line_count;


        int i,j=0 , slash = 0;
        yyleng--;
        char *yycopy = strdup( yytext );
        char array[yyleng-1];
        
         
        
        for ( i = 1; i <yyleng;i++ ) {
        
        if(yycopy[i]=='"') 
        {
        array[j] = yycopy[i];
        j++;
        continue;
        }


        if(yycopy[i]=='\n')
        {
             line_count++;
        }


        if(yycopy[i-1]!='\\' && yycopy[i]=='\\') 
        {
        slash=1;
        continue;
        }

        if(slash ==0)  
        {
        array[j] = yycopy[i];
        j++;
        }


        else 
        {

        

        if(yycopy[i]=='n') {
        
        array[j] = '\n';
        j++;
        }

        else if(yycopy[i]=='t') {
        
        array[j] = '\t';
        j++;
        }

        
        else if(yycopy[i]=='\\') {
        
        array[j] = '\\';
        j++;
        }


        else if(yycopy[i]=='a') {
        
        array[j] = '\a';
        j++;
        }


        else if(yycopy[i]=='f') {
        
        array[j] = '\f';
        j++;
        }


        else if(yycopy[i]=='r') {
        
        array[j] = '\r';
        j++;
        }


        else if(yycopy[i]=='b') {
        
        array[j] = '\b';
        j++;
        }


        else if(yycopy[i]=='v') {
        
        array[j] = '\v';
        j++;
        }


        else if(yycopy[i]=='0') {
        
        array[j] = '\0';
        j++;
        }

        slash=0;
        }
        }

        array[j] = '\0';
        j++;


        char array1[j];
        for (int k=0; k<j; k++) 
        {

        array1[k]=array[k];
        
        }
        
    
        free( yycopy );
    
        fprintf(tokenout,"<STRING,%s>",array1);
        fprintf(logout,"Line no %d: TOKEN <STRING> Lexeme %s found\n",line_no,yytext);
        
                


           }



{UNFINISHED_STRING} {
        

        fprintf(logout,"Error at Line no %d: UNFINISHED STRING found %s\n",line_count,yytext);
    
        int i,j=0,slash = 0;
        

        yyleng--;
        char *yycopy = strdup( yytext );
        char arr[yyleng-1];
        
         
        for ( i = 1; i <yyleng;i++ ) {
        if(yycopy[i]=='\n') line_count++;}
       
        
        free( yycopy );

        error_count++;
    
        
        }


"\/\/" {
    BEGIN COMMENT;
    fprintf(tokenout,"<COMMENT>");
    fprintf(logout,"Line no %d: TOKEN <COMMENT> Lexeme //",line_count);
}

<COMMENT>(\\){NEWLINE} {
    char c = '\n';
    line_count++;
    fprintf(logout,"%c",c);
}
<COMMENT>{NEWLINE} {
    
    fprintf(logout," found\n");
    line_count++;
    BEGIN INITIAL;
}

<COMMENT>. {
    fprintf(logout,"%s",yytext);
}


"\/*" {
    BEGIN MULTI_LINE_COMMENT;
    copyComment = "/*";
    commentLine = line_count;
}


<MULTI_LINE_COMMENT>{NEWLINE} {
    line_count++;
    copyComment= copyComment + "\n";
}


<MULTI_LINE_COMMENT>("*\/") {
    BEGIN INITIAL;
    fprintf(tokenout,"<COMMENT>");
    
    copyComment = copyComment + "*/";
    fprintf(logout,"Line no %d: :TOKEN <COMMENT> Lexeme ",commentLine);
    fprintf(logout,"%s found\n",copyComment.c_str());
}

<MULTI_LINE_COMMENT>. {
    
    copyComment = copyComment + yytext;
}

<MULTI_LINE_COMMENT><<EOF>> {
   BEGIN INITIAL;
   error_count++;
   line_count--;
   fprintf(logout,"Error at Line no %d: UNFINISHED COMMENT %s\n",commentLine,copyComment.c_str());
   fprintf(logout,"Total lines = %d\nTotal errors = %d",line_count,error_count);
   return 0;
}
{HEX}  {
         fprintf(logout,"Hex number %s found at line no %d\n",yytext,line_count);

  num=atoi(yytext);
        while(num!=0)
        {
            r=num%16;
            digit='0'+r;
            if(digit>'9')
            digit+=7;
            a[count++]=digit;
            num=num/16;
        }
        for(i=count-1;i>=pcount;--i)
                printf("%c",a[i]);
                pcount=count;
       

       }
                       



{TOO_MANY_DECIMAL_POINTS} {
        
        fprintf(logout,"Error at Line no %d: TOO MANY DECIMAL POINTS found %s\n",line_count,yytext);
        error_count++;
        }

{ILLFORMED_NUMBER} {
        
        fprintf(logout,"Error at Line no %d: ILLFORMED NUMBER found %s\n",line_count,yytext);
        error_count++;
        }


{INVALID_ID} {
        
        fprintf(logout,"Error at Line no %d: INVALID IDENTIFIER found %s\n",line_count,yytext);
        error_count++;
        }



{MULTI_CHAR} {
        
        fprintf(logout,"Error at Line no %d: MULTICHARACTER CONSTANT ERROR found %s\n",line_count,yytext);
        error_count++;
        }

{UNTERMINATED_CHAR} {
        
        fprintf(logout,"Error at Line no %d: UNTERMINATED CHARACTER found %s\n",line_count,yytext);
        error_count++;
        }


{UNRECOGNIZED_CHAR} {
        

        fprintf(logout,"Error at Line no %d: UNRECOGNIZED CHARACTER found %s\n",line_count,yytext);
        error_count++;
 
        }


        

{EMPTY_CHAR} {
        
        fprintf(logout,"Error at Line no %d: EMPTY CHARACTER found %s\n",line_count,yytext);
         error_count++;
        }



        












<<EOF>> {
            line_count--;
                        //printf("Total Line Number: %d and error: %d\n",line_count,error_count); 
                        fprintf(logout,"Total Line Number: %d and error : %d\n",line_count,error_count); 
                        return 0;
                        }        
        




                   
            

%%

int main(int argc,char *argv[]){
    
    if(argc!=2){
        printf("Please provide input file name and try again\n");
        return 0;
    }
    
    FILE *fin=fopen(argv[1],"r");
    if(fin==NULL){
        printf("Cannot open specified file\n");
        return 0;
    }
    
    logout= fopen("1605102_log.txt","w");
    tokenout= fopen("1605102_token.txt","w");

    yyin= fin;
    yylex();
    //st.printAllScopes();
    fclose(yyin);
    fclose(tokenout);
    fclose(logout);
    return 0;
}
