import os

os.system("make")

for i in range(1, 8):
    os.system("./codegen < testcases/demo{}".format(i))
    mine = os.popen("~/Desktop/ILOC_SIMULATOR/sim < iloc.out").read()
    os.system("./sol-codegen < testcases/demo{}".format(i))
    os.system("~/Desktop/ILOC_SIMULATOR/sim < iloc.out")
    #print(i, mine == answer)