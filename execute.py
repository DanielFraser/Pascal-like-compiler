import os
import IlocSim as sim

def getIloc():
    with open('iloc.out', 'r') as code:
        iloc = code.read()
    return iloc

os.system("make")
os.system("codegen < testcases/demo3")
#sim.start(getIloc())