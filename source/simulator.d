module simulator;

import std.process;
import std.stdio;
import std.conv;
import std.array;

import arsd.terminal;

import instruction;
import register;


enum BranchType
{
	none,
	absolute,
	relative
}


struct ProgramCounter
{
	ubyte address;

	void reset()
	{
		address = 0;
	}

	void clock(BranchType branch = BranchType.none, byte offset = 0)
	{
		switch (branch)
		{
		case BranchType.absolute:
			address = offset;
			break;
		case BranchType.relative:
			address += 1 + offset;
			break;
		default:
			address += 1;
			break;
		}
	}
}


enum ALU_OP
{
	OR,
	ADD,
	SUB,
	INV
}

byte ALU(ALU_OP op, byte A, byte B)
{
	switch (op)
	{
	case ALU_OP.OR:  return A | B;
	case ALU_OP.ADD: return cast(byte)(cast(int)(A) + cast(int)(B));
	case ALU_OP.SUB: return cast(byte)(cast(int)(A) - cast(int)(B));
	default:         return cast(byte)(-cast(int)(A));
	}
}

struct RegisterFile
{
	const byte r0 = 0;

private:
	byte r1;
	byte r2;
	byte r3;
	byte r4;
	byte r5;
	byte r6;
	byte ap;

public:
	void reset()
	{
		ap = 0;
		r1 = 0;
		r2 = 0;
		r3 = 0;
		r4 = 0;
		r5 = 0;
		r6 = 0;
	}

	byte read(RegisterType r)
	{
		switch (r)
		{
		case RegisterType.r0: return r0;
		case RegisterType.r1: return r1;
		case RegisterType.r2: return r2;
		case RegisterType.r3: return r3;
		case RegisterType.r4: return r4;
		case RegisterType.r5: return r5;
		case RegisterType.r6: return r6;
		case RegisterType.ap: return ap;
		default:              return r0;
		}
	}

	void write(RegisterType rs, byte data)
	{
		switch (rs)
		{
		case RegisterType.r1: r1 = data; return;
		case RegisterType.r2: r2 = data; return;
		case RegisterType.r3: r3 = data; return;
		case RegisterType.r4: r4 = data; return;
		case RegisterType.r5: r5 = data; return;
		case RegisterType.r6: r6 = data; return;
		case RegisterType.ap: ap = data; return;
		default:                         return;
		}
	}
}


struct Simulator
{
	Instruction[ubyte.max + 1] instructions;
	ProgramCounter pc;
	byte[ubyte.max + 1] memory;
	RegisterFile registers;

	Terminal* terminal;

	this(Instruction[ubyte.max + 1] instructions)
	{
		this.instructions = instructions;

		this.terminal = new Terminal(ConsoleOutputType.linear);
	}

	string parameters_to_string()
	{
		string parameters_string = "(";
		foreach (i, parameter; this.instructions[this.pc.address].parameters)
		{
			if (i != 0)
				parameters_string ~= ", ";
			if (parameter.type == InstructionParameterType.register)
				parameters_string ~= to!string(parameter.register) ~ ": register";
			else
				parameters_string ~= to!string(parameter.number) ~ ": number";
		}
		parameters_string ~= ");";
		return parameters_string;
	}

	void start(double ticks_per_second = 1)
	{
		this.sleep(1 / ticks_per_second);
		this.clear_output();
		this.write_output("Refresh rate / Speed (in seconds): " ~ to!string(1 / ticks_per_second));
		this.tick();

		this.start(ticks_per_second);
	}

	void tick()
	{
		this.write_output("Instruction: " ~
							this.instructions[this.pc.address].type ~
							this.parameters_to_string());

		this.execute_current_instruction();

		this.write_output("Registers:\t" ~
			"r0: " ~ to!string(registers.r0) ~ "\t" ~
			"r1: " ~ to!string(registers.r1) ~ "\t" ~ 
			"r2: " ~ to!string(registers.r2) ~ "\t" ~ 
			"r3: " ~ to!string(registers.r3) ~ "\t" ~ 
			"r4: " ~ to!string(registers.r4) ~ "\t" ~ 
			"r5: " ~ to!string(registers.r5) ~ "\t" ~ 
			"r6: " ~ to!string(registers.r6) ~ "\t" ~ 
			"ap: " ~ to!string(registers.ap));

		this.write_output("Memory:");
		foreach (i; 0..16)           // 16 rows
		{
			string line = "";
			foreach(j; 0..16)		 // 16 cols
			{
				line ~= "\t";
				if (cast(ubyte)(i * 16 + j) == registers.ap)
					line ~= this.make_red(to!string(memory[i * 16 + j]));
				else
					line ~= to!string(memory[i * 16 + j]);
			}
			this.write_output(line);
		}
	}

	private void execute_current_instruction()
	{
		Instruction current_instruction = this.instructions[this.pc.address];
		switch(current_instruction.type)
		{
		case InstructionType.noop:
			break;
		case InstructionType.zero:
			this.registers.write(current_instruction.parameters[0].register, 0);
			break;
		case InstructionType.inc:
			this.registers.write(
				current_instruction.parameters[0].register,
				ALU(ALU_OP.ADD, this.registers.read(current_instruction.parameters[0].register), 1));
			break;
		case InstructionType.dec:
			this.registers.write(
				current_instruction.parameters[0].register,
				ALU(ALU_OP.SUB, this.registers.read(current_instruction.parameters[0].register), 1));
			break;
		case InstructionType.inv:
			this.memory[this.registers.read(RegisterType.ap)] = 
						ALU(ALU_OP.INV, this.registers.read(current_instruction.parameters[0].register), 0);
			break;
		case InstructionType.load:
			this.registers.write(
				current_instruction.parameters[0].register,
				this.memory[this.registers.read(RegisterType.ap)]);
			break;
		case InstructionType.store:
			this.memory[this.registers.read(RegisterType.ap)] = 
						this.registers.read(current_instruction.parameters[0].register);
			break;
		case InstructionType.brnz:
			if (this.memory[this.registers.read(RegisterType.ap)] != 0) 
				pc.clock(BranchType.relative, cast(byte)(current_instruction.parameters[0].number));
			return;
		case InstructionType.j:
			pc.clock(BranchType.absolute, cast(ubyte)(current_instruction.parameters[0].number));
			return;
		case InstructionType.jal:
			this.memory[this.registers.read(RegisterType.ap)] = this.pc.address;
			pc.clock(BranchType.absolute, cast(ubyte)(current_instruction.parameters[0].number));
			return;
		case InstructionType.or:
			this.memory[this.registers.read(RegisterType.ap)] = 
						ALU(ALU_OP.OR,
							this.registers.read(current_instruction.parameters[0].register),
							this.registers.read(current_instruction.parameters[1].register));
			break;
		case InstructionType.add:
			this.memory[this.registers.read(RegisterType.ap)] = 
						ALU(ALU_OP.ADD,
							this.registers.read(current_instruction.parameters[0].register),
							this.registers.read(current_instruction.parameters[1].register));
			break;
		case InstructionType.sub:
			this.memory[this.registers.read(RegisterType.ap)] = 
						ALU(ALU_OP.SUB,
							this.registers.read(current_instruction.parameters[0].register),
							this.registers.read(current_instruction.parameters[1].register));
			break;
		default:
			break;
		}

		pc.clock();
	}

	void write_output(const string text)
	{
		spawnShell("echo \"" ~ text ~ "\"").wait;
	}

	string make_red(const string text)
	{
		return "\033[31m" ~ text ~ "\033[0m";
	}

	void clear_output()
	{
		spawnShell("clear").wait;
	}

	void sleep(const double seconds)
	{
		spawnShell("sleep " ~ to!string(seconds) ~ "s").wait;
	}
}
