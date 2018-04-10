import os
import IlocSim as sim

def getIloc():
    with open('iloc.out', 'r') as code:
        iloc = code.read()
    return iloc

os.system("make")
# os.system("codegen < testcases/demo1")
# sim.start(getIloc())
os.system("codegen < testcases/demo2")
# sim.start(getIloc())