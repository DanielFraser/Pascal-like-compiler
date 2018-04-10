/**********************************************
        CS415  Project 2
        Spring  2018
        Student Version
**********************************************/

#include "attr.h" 
#include <stdlib.h>
#include <string.h>

Node* head = NULL; //head of linked list

/*
* Function: clearList
*-----------------------
*  Clears all allocated memory given the the linked list
*/
void clearList()
{
    Node** tempHead = &head;
    Node* cursor = head; //points to where head is actually pointing at
    Node* nodeToDelete = NULL; //design to hold the node to be deleted
    while (cursor != NULL) //loops through linked list until it hits the end
    {
        nodeToDelete = cursor; //moves the cursor node to nodeTODelete so it can be cleared
        cursor = (Node*) cursor->next; //moves the cursor to next node in the list
        nodeToDelete -> next = NULL; //clears pointer
        free(nodeToDelete -> string); //clears string since memory is allocated
        free(nodeToDelete); //clears the struct itself and the memory allocated
    }
    head = NULL; //clears the head node itself
}

//add to linked list (order doesn't matter)
void addToList(char* str)
{
    Node* temp = malloc(sizeof(Node));
    temp -> string = malloc(strlen(str)+1);
    temp -> string = strncpy(temp->string,str,strlen(str)+1); //copy string
    temp-> string[strlen(str)] = '\0';
    temp -> next = NULL;
    //temp -> next = head;
    //head = temp;
    if (head)
    {
        Node* cursor = head;
        while(cursor -> next)
            cursor = cursor -> next;
        cursor -> next = temp;
    }
    else
    {
        head = temp;
    }
}

//return linked list
Node* getVarList()
{
    return head;
}