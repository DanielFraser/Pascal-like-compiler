# get iloc
# make dict of values
# make switch for each type
# print final result
import re

registers = dict()
mem = dict()
cycles = 0

def accessMem(num, value=None):

    if not value:
        if num not in mem:
            return 0
        return mem[num]
    else:
        mem[num] = value


def parse(line):
    three = ["store", "load"]
    two = ["mult", "div"]
    action = line.split()[0]
    global cycles
    if any(x in action for x in three) and "loadI" not in action:
        cycles += 5
    elif any(x in action for x in two):
        cycles += 3
    else:
        cycles += 1

    if action == "loadAI":
        regs = re.findall('(r\d+)', line)[1]
        count = int(re.search(', *(-?\d+)', line).group(1))
        registers[regs] = accessMem(count+1024)

    elif action == "loadI":
        regs = re.findall('(r\d+)', line)[0]
        count = int(re.search('(\d+)', line).group(1))
        registers[regs] = count

    elif action == "load":
        regs = re.findall('(r\d+)', line)
        registers[regs[1]] = accessMem(registers[regs[0]])

    elif action == "storeAI":
        regs = re.findall('(r\d+)', line)[0]
        count = int(re.search(', *(-?\d+)', line).group(1))
        accessMem(count+1024,  registers[regs])

    elif action == "store":
        regs = re.findall('(r\d+)', line)
        accessMem(registers[regs[1]], registers[regs[0]])

    elif action == "addI":
        regs = re.findall('(r\d+)', line)
        count = int(re.search(', *(\d+)', line).group(1))
        registers[regs[1]] = registers[regs[0]] + count

    elif action == "subI":
        regs = re.findall('(r\d+)', line)
        count = int(re.search(', *(\d+)', line).group(1))
        registers[regs[1]] = registers[regs[0]] - count

    elif action == "add":
        regs = re.findall('(r\d+)', line)
        registers[regs[2]] = registers[regs[0]] + registers[regs[1]]

    elif action == "sub":
        regs = re.findall('(r\d+)', line)
        registers[regs[2]] = registers[regs[0]] - registers[regs[1]]

    elif action == "mult":
        regs = re.findall('(r\d+)', line)
        registers[regs[2]] = registers[regs[0]] * registers[regs[1]]

    elif action == "output":
        count = int(re.search('(\d+)', line).group(1))
        print(mem[count])

    elif action == "outputAI":
        count = int(re.search(', *(-*\d+)', line).group(1))
        print(mem[count+1024])

    elif action == "rshift":
        regs = re.findall('(r\d+)', line)
        registers[regs[2]] =  registers[regs[0]] >> registers[regs[1]]

    elif action == "rshift":
        regs = re.findall('(r\d+)', line)
        registers[regs[2]] = registers[regs[0]] << registers[regs[1]]

    else:
        print(action)

def start(iloc):
    lines = 0
    for line in iloc.split('\n'):
        line = line.strip()
        if line and "//" not in line:
            parse(line)
            lines += 1
    print("cycles = {} and lines = {}".format(cycles, lines))

if __name__ == '__main__':
    lines = 0
    with open('iloc.out', 'r') as f:  # opens the file (its designed to read large text files
        for line in f:  # goes through each line, one at a time
            line = line.strip()
            if line and "//" not in line:
                parse(line)
                lines += 1
    print("cycles = {} and lines = {}".format(cycles, lines))