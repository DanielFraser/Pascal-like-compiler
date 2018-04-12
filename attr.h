/**********************************************
        CS415  Project 2
        Spring  2015
        Student Version
**********************************************/

#ifndef ATTR_H
#define ATTR_H

typedef union {int num; char *str;} tokentype;

typedef enum type_expression {TYPE_INT=0, TYPE_BOOL, TYPE_ERROR} Type_Expression;

typedef enum var_expression {TYPE_SCALAR, TYPE_ARRAY} Var_type;

typedef struct {
        Type_Expression type;
        int targetRegister;
        } regInfo;

typedef struct
{
    int initial; //loop start
    int cond; //loop true
    int endLbl; //loop end
}LabelList;

static int inductionVar = 0;

/*
 *the Nodes that will make up the linked list
 */
typedef struct LinkedList
{
    char* string; //designed to hold the string
    struct LinkedList* next; //connects the node to another
}Node;

void clearList();
void addToList();
Node* getVarList();


#endif


  
