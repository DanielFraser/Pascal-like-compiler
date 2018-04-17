import random
import string

maxdepth = 2

# generate 3 character word starting with an letter
def randomWord():
    name = random.choice(string.ascii_lowercase)
    name += ''.join(random.choice(string.ascii_lowercase+string.digits) for _ in range(2))
    return name

#generate n random names
def generateVars():
    while len(varList) < vars:
        varList.add(randomWord())

# declares type for declarations
def boolOrint():
    return random.choice(["boolean", "integer"])

# creates the declarations using the variables
def createVarDecs(varList):
    global demo
    varList = list(varList)

    while varList:
        lst = varList[:4]
        varList = varList[5:]
        dec = "\t"
        dec += ', '.join(lst)
        demo += dec + " : {}\n".format(boolOrint())

def initialVal(varList):
    global demo
    for x in varList:
        demo += "\t{} := {};\n".format(x, random.randint(0, 10))

def stmtlist(depth):
    global demo
    if random.randint(0, 1) and depth < maxdepth:
        stmtlist(depth+1)
        demo += ";\n"
        stmt()
    else:
        stmt()


def stmt():
    choice = random.choice(["if", "while", "assign", "write"])
    if choice == "if":
        ifstmt()
    elif choice == "while":
        wstmt()
    elif choice == "assign":
        astmt()
    elif choice == "write":
        writestmt()

def ifstmt():
    global demo
    demo += "while "
    condexp(1)
    demo += " do\n"
    stmt()
    demo += "else\n"
    stmt()


def wstmt():
    global demo
    demo += "if "
    condexp(1)
    demo += " then\n"
    stmt()

def astmt():
    global demo
    global varList
    vars = list(varList)
    demo += "{} = ".format(vars[random.randint(0, len(vars)-1)])
    exp()
    demo += "\n"

def writestmt():
    global demo
    demo += "print("
    exp()
    demo += ")\n"

def cmpdstmt():
    global demo
    demo += "begin\n"
    stmtlist(0)
    demo += "end."

def condexp(loop = 0):
    pass

def exp():
    pass

demo = "program main;\n"
demo += "var"
vars = random.randint(6, 20)
varList = set()
generateVars()
createVarDecs(varList)
demo += "begin\n"
initialVal(varList)
demo += "end."
print(demo)