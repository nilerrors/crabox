module register;


const string[] registers = [
    "r0",
    "r1",
    "r2",
    "r3",
    "r4",
    "r5",
    "r6",
    "ap",
];

enum RegisterType
{
    r0 = "r0",
    r1 = "r1",
    r2 = "r2",
    r3 = "r3",
    r4 = "r4",
    r5 = "r5",
    r6 = "r6",
    ap = "ap",
}

RegisterType get_register_type(const string type)
{
    switch(type)
    {
    case "r0": return RegisterType.r0;
    case "r1": return RegisterType.r1;
    case "r2": return RegisterType.r2;
    case "r3": return RegisterType.r3;
    case "r4": return RegisterType.r4;
    case "r5": return RegisterType.r5;
    case "r6": return RegisterType.r6;
    case "ap": return RegisterType.ap;
    default:   return RegisterType.r0;
    }
}


bool is_register(const string value)
{
    foreach (register; registers)
    {
        if (value == register)
        {
            return true;
        }
    }

    return false;
}


string register_to_bin(const string register)
{
    switch (register)
    {
        case "r0":
            return "000";
        case "r1":
            return "001";
        case "r2":
            return "010";
        case "r3":
            return "011";
        case "r4":
            return "100";
        case "r5":
            return "101";
        case "r6":
            return "110";
        case "ap":
            return "111";
        default:
            return "000";
    }
}

