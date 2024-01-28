module instruction;

import register;


const string[] instructions = [
    "zero",
    "inc",
    "dec",
    "load",
    "store",
    "brnz",
    "j",
    "jal",
    "or",
    "add",
    "sub",
    "inv",
    "noop"
];


bool is_instruction(const string value)
{
    foreach (instruction; instructions)
    {
        if (value == instruction)
        {
            return true;
        }
    }

    return false;
}


enum InstructionType
{
    zero  = "zero",
    inc   = "inc",
    dec   = "dec",
    load  = "load",
    store = "store",
    brnz  = "brnz",
    j     = "j",
    jal   = "jal",
    or    = "or",
    add   = "add",
    sub   = "sub",
    inv   = "inv",
    noop  = "noop"
}

InstructionType get_instruction_type(const string instruction_type)
{
    switch (instruction_type)
    {
    case "zero":  return InstructionType.zero;
    case "inc":   return InstructionType.inc;
    case "dec":   return InstructionType.dec;
    case "load":  return InstructionType.load;
    case "store": return InstructionType.store;
    case "brnz":  return InstructionType.brnz;
    case "j":     return InstructionType.j;
    case "jal":   return InstructionType.jal;
    case "or":    return InstructionType.or;
    case "add":   return InstructionType.add;
    case "sub":   return InstructionType.sub;
    case "inv":   return InstructionType.inv;
    default:      return InstructionType.noop;
    }
}

enum InstructionParameterType
{
    number = "number",
    register = "register",
}

struct InstructionParameter
{
    InstructionParameterType type;
    union
    {
        RegisterType register;
        int          number;
    };

    this(InstructionParameterType type, RegisterType register)
    {
        this.type = type;
        this.register = register;
    }

    this(InstructionParameterType type, int number)
    {
        this.type = type;
        this.number = number;
    }
}


struct Instruction
{
    InstructionType type;
    InstructionParameter[] parameters;
}

