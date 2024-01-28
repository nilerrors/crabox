import std.stdio;
import std.file;
import std.string;
import std.conv;

import arsd.terminal;

import cli;
import lexer;
import compiler;
import simulator;


void main(const string[] args)
{
    if (args.length == 1)
    {
        help();
        return;
    }

    if (args[1] != "bin" && args[1] != "hex" && args[1] != "logisim" && args[1] != "simulate")
    {
        writeln("command not found: ", args[1]);
        help();
        return;
    }

    auto file_arg = cli.find_opt(args, "-f");
    auto source_arg = cli.find_opt(args, "-s");

    if (args[1] == "simulate")
    {
        auto tps_arg = cli.find_opt(args, "-tps");

        if (!source_arg.found)
        {
            writeln("source file not given");
            return;
        }

        string source = cast(const(string))read(source_arg.option);

        auto compiler = Compiler(Lexer(source).lex());
        auto instructions = compiler.to_instructions();
        auto errors = compiler.any_errors();

        if (errors.length > 0)
        {
            foreach (string error; errors)
            {
                writeln(error);
            }
        }
        else
        {
            Simulator simulator = Simulator(instructions);
            double ticks_per_second = 1;
            if (tps_arg.found)
            {
                try
                    ticks_per_second = to!double(tps_arg.option);
                catch(ConvException err)
                {
                    writeln("expected double for `ticks per second`, got: ", tps_arg.option);
                    return;
                }
            }
            simulator.start(ticks_per_second);
        }
        

        return;
    }

    if (!source_arg.found)
    {
        auto repl = REPL(file_arg, args[1]);
        repl.start();
        
        return;
    }

    if (!exists(source_arg.option))
    {
        writeln("file not found: ", source_arg.option);
        return;
    }

    if (!isFile(source_arg.option))
    {
        writeln("not a file: ", source_arg.option);
        return;
    }

    if (file_arg.found && exists(file_arg.option) && !isFile(file_arg.option))
    {
        writeln("not a file: ", file_arg.option);
        return;
    }

    string source = cast(const(string))read(source_arg.option);
    auto compiler = Compiler(Lexer(source).lex());

    string output;
    switch (args[1])
    {
    case "bin":
        output = compiler.to_bin();
        break;
    case "hex":
        output = compiler.to_hex();
        break;
    case "logisim":
        output = compiler.to_logisim();
        break;
    default:
        unknown_command_error(args[1]);
        return;
    }

    if (!file_arg.found)
    {
        writeln(output);
        return;
    }

    toFile!(string)(output, file_arg.option);
}
