/**********************************************
        CS415  Project 2
        Spring  2018
        Student Version
**********************************************/

#include "attr.h" 
#include <stdlib.h>

Node* head = NULL; //

//clear list and free everything
void clearList()
{

}

//add to linked list (order doesn't matter)
void addToList(char* str)
{
    if (!head)
    {
        head = malloc(sizeof(Node));
        head -> str = malloc(strlen(str));
        head -> str = str;
    }
}

//return linked list
Node* getVarList()
{
    return head;
}