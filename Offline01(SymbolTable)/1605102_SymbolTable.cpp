#include <bits/stdc++.h>


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
        test = lookupInScopeTable(sName);//checks if the symbol is already in the scope table or not.If not,then it inserts the new symbol

        if(test == 0)


        {
            //cout<<"not present already"<<endl;
            symbolInfo *newNode = new symbolInfo(sName,sType);

            symbolInfo *temp;

            temp=symbolList[hashValue];

            if(temp==0)
            {
                symbolList[hashValue] = newNode;
                cout<<"Inserted in ScopeTable #"<<scopeID<<" at position "<<hashValue<<",0"<<endl;


                return true;
            }

            while(temp->Next!=0)
            {
                pos++;

                temp=temp->Next;

            }
            pos++;
            temp->Next=newNode;
            cout<<"Inserted in ScopeTable #"<<scopeID<<" at position "<<hashValue<<","<<pos<<endl;



            return true;

        }

        else
        {
            cout<<"Already exists in the Scopetable."<<endl;
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
                // cout<<"Symbol found."<<endl;
                cout<<"Found in ScopeTable #"<<scopeID<<" at position "<<hash1<<","<<pos<<endl;
                return temp ;
            }
            pos++;
            temp = temp->Next ; //move to next node
        }
        cout<<"Symbol not found."<<endl;
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
            temp = temp->Next ; //move to next node
        }
        if (temp == 0)
        {
            cout<<"Symbol not found to delete."<<endl;
            return false ;
        }//item not found to delete
        if (temp == symbolList[hash2]) //delete the first node
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


        cout<<"ScopeTable #"<<scopeID<<endl;
        for(int i=0 ; i<Size ; i++)
        {
            symbolInfo * temp;
            temp = symbolList[i];
            cout<<i<<" -->  ";
            while(temp!=0)
            {
                cout<<" < "<<temp->getName()<<" : "<<temp->getType()<<" > ";

                temp = temp->Next;
            }
            printf("\n");
        }




        //printf("Length: %d\n",length);*/
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


int main()
{

    freopen("1605102_input.txt","r",stdin);
    freopen("1605102_output.txt","w",stdout);

    int bucket;
    string x,i,i1,p,s,e,d,l;

    cin>>bucket;
    // cout<<bucket<<endl;
    symbolTable sym(bucket);

    while(cin>>x)
    {
        if(x=="I")
        {
            cin>>i>>i1;
            cout<<x<<"  "<<i<<"  "<<i1<<endl;
            sym.insertIntoSymbolTale(i,i1);
            cout<<endl;


        }

        else if(x=="L")
        {
            cin>>l;
            cout<<x<<"  "<<l<<endl;
            symbolInfo *temp;
            temp=sym.lookUp(l);
            if(temp!=0)
                cout<<"Symbol found ("<<temp->getName()<<","<<temp->getType()<<")"<<endl;
                 cout<<endl;

        }

        else if(x=="D")
        {
            cin>>d;
            cout<<x<<"  "<<d<<endl;
            sym.deleteFromSymbolTale(d);
             cout<<endl;
        }

        else if(x=="P")
        {
            cin>>p;
            cout<<x<<"  "<<p<<endl;
            if(p=="A")
            {

                sym.printAllScopes();
            }
            if(p=="C")
            {
                sym.printCurrentScope();
            }
             cout<<endl;
        }

        else if(x=="S")
        {
            cout<<x<<endl;

            sym.enterScope();
             cout<<endl;
        }

        else if(x=="E")
        {
            cout<<x<<endl;
            sym.exitScope();
             cout<<endl;
        }
    }


    return 0;
}






