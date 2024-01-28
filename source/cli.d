module cli;

import std.stdio;
import std.file;
import std.typecons;
import std.algorithm;

import arsd.terminal;

import lexer;
import compiler;


void help()
{
	writeln("crabox [cmd] -s [source] -f [output]");
	writeln("commands:");
	writeln("\tbin, hex, logisim, simulate");
}

void unknown_command_error(const string command)
{
	writeln("unknown command: ", command);
}

Tuple!(bool, "found", string, "option") find_opt(const string[] args, const string flag)
{
	int i = 0;
	while (i < args.length)
	{
		if (args[i] == flag && i + 1 < args.length)
			return tuple!("found", "option")(true, args[i + 1]);

		i++;
	}

	return tuple!("found", "option")(false, "");
}


struct REPL
{
	Terminal* terminal;
	Compiler compiler;
	string line;
	Tuple!(bool, "found", string, "option") file_arg;
	string representation;

	this(Tuple!(bool, "found", string, "option") file_arg, string representation)
	{
		terminal = new Terminal(ConsoleOutputType.linear);
		compiler = Compiler();
		this.file_arg = file_arg;
		this.representation = representation;
	}

	void handleClear()
	{
		compiler = Compiler();
		terminal.clear();
	}

	void handleStore()
	{
		if (line != ".store")
		{
	        string file = line[".store".length .. $];

	        if (exists(file) && !isFile(file))
	        {
	            terminal.writeln("not a file: ", file);
	        }
	        else
	        {
	            file_arg.option = line[".store".length .. $];
	            file_arg.found = true;
	        }
	    }
	    else if (!file_arg.found)
	    {
	        terminal.color(Color.green, Color.black);
	        terminal.write("file to write to: ");
	        terminal.color(Color.DEFAULT, Color.DEFAULT);
	        file_arg.option = terminal.getline();
	        file_arg.found = true;
	    }
	    toFile!(string)(compiler.to_repr_all(representation), file_arg.option);
	    terminal.color(Color.green, Color.black);
	    terminal.writeln("written to file: ", file_arg.option);
	    terminal.color(Color.DEFAULT, Color.DEFAULT);
	}

	void handleInstruction()
	{
		compiler.feed(Lexer(line).lex());
        string compiled_code = compiler.to_repr(representation);
        auto errors = compiler.any_errors();
        if (errors.length > 0)
        {
            foreach (string error; errors)
            {
                terminal.color(Color.red, Color.black);
                terminal.writeln(error);
                terminal.color(Color.DEFAULT, Color.DEFAULT);
            }
        }
        else
        {
            terminal.writeln(compiled_code);
        }
	}

	void start()
	{
		terminal.setTitle("Crabox");
		terminal.clear();

		try
		{
		    do {
		        if (line == ".quit")
		        	break;
		        else if (line == ".clear")
		            this.handleClear();
		        else if (startsWith(line, ".store"))
		            this.handleStore();
		        else if (line != "")
		            this.handleInstruction();
		        
		        terminal.color(Color.cyan, Color.black);
		        terminal.write(">> ");
		        terminal.color(Color.DEFAULT, Color.DEFAULT);
		    }
		    while ((line = terminal.getline()) !is null);
		    writeln();
		}
		catch (UserInterruptionException error)
		{
		    writeln();
		}
	}
}
