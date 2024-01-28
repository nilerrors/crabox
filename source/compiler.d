module compiler;

import std.conv;
import std.array;
import std.typecons;
import std.algorithm;
import std.stdio;
import core.stdc.stdlib;

import instruction;
import register;
import bin_convs;
import token;
import lexer;


struct Compiler
{
    Token[] tokens;
    string[] errors;
    Instruction[ubyte.max + 1] instructions;
    ubyte current_instruction;
    string bin;
    ulong current;

    this(Token[] tokens)
    {
        this.tokens = tokens;
    }

    string[] any_errors()
    {
        return this.errors;
    }

    void feed(Token[] tokens)
    {
        errors = [];
        if (this.tokens.length > 0)
        {
            this.tokens = this.tokens.remove(this.tokens.length - 1);
            this.current = this.tokens.length;
        }
        this.tokens ~= tokens;
    }

    string to_repr_all(const string representation)
    {
        current = 0;
        switch (representation)
        {
        case "bin":
            return this.to_bin();
        case "hex":
            return this.to_hex();
        case "logisim":
            return this.to_logisim();
        default:
            return "";
        }
    }

    string to_repr(const string representation)
    {
        switch (representation)
        {
        case "bin":
            return this.to_bin();
        case "hex":
            return this.to_hex();
        case "logisim":
            return this.to_logisim();
        default:
            return "";
        }
    }

    Instruction[ubyte.max + 1] to_instructions()
    {
        while (current < this.tokens.length)
        {
            switch (this.tokens[current].type)
            {
            case TokenType.eol, TokenType.eof:
                break;
            case TokenType.instruction:
                this.handleToInstruction();
                current++;
                if (current < this.tokens.length
                    && this.tokens[current].type != TokenType.eol
                    && this.tokens[current].type != TokenType.eof)
                {
                    errors ~= "expected newline, got token of type "
                            ~ this.tokens[current].type ~ ": "
                            ~ "'" ~ this.tokens[current].value ~ "'"; 
                }
                break;
            default:
                errors ~= "unexpected token of type "
                        ~ this.tokens[current].type ~ ": "
                        ~ "'" ~ this.tokens[current].value ~ "'";
                break;
            }

            current++;
        }

        return this.instructions;
    }

    void handleToInstruction()
    {
        Instruction instruction;

        switch (this.tokens[current].value)
        {
        case "zero", "inc", "dec", "load", "store", "inv":
            if (!this.canPeek())
            {
                errors ~= "insufficient arguments, expected 1 argument: " ~ TokenType.register;
            }
            else if (!is_register(this.peek().value))
            {
                errors ~= "expected register, got token of type "
                        ~ this.peek().type ~ ": "
                        ~ "'" ~ this.peek().value ~ "'";
            }
            else
            {
                instruction.type = get_instruction_type(this.tokens[current].value);
                instruction.parameters ~= InstructionParameter(InstructionParameterType.register, get_register_type(this.peek().value));

                instructions[current_instruction] = instruction;
                current_instruction++;
            }
            break;
        case "brnz", "j", "jal":
            if (!this.canPeek())
            {
                errors ~= "insufficient arguments, expected 1 argument: " ~ TokenType.number;
            }
            else if (this.peek().type != TokenType.number)
            {
                errors ~= "expected number, got token of type "
                        ~ this.peek().type ~ ": "
                        ~ "'" ~ this.peek().value ~ "'";
            }
            else if ((this.tokens[current].value == "brnz" && !is_6bit_2s_complement(this.peek().value)) ||
                (this.tokens[current].value != "brnz" && !is_6bit_unsigned(this.peek().value)))
            {
                errors ~= "number out of range: " ~ this.peek().value;
            }
            else
            {
                instruction.type = get_instruction_type(this.tokens[current].value);
                instruction.parameters ~= InstructionParameter(InstructionParameterType.number, to!int(this.peek().value));

                instructions[current_instruction] = instruction;
                current_instruction++;
            }
            break;
        case "or", "add", "sub":
            if (!this.canDoublePeek())
            {
                errors ~= "insufficient arguments, expected 2 arguments: " ~ TokenType.register
                        ~ " and " ~ TokenType.register;
            }
            instruction.type = get_instruction_type(this.tokens[current].value);
            instruction.parameters ~= InstructionParameter(InstructionParameterType.register, get_register_type(this.peek().value));
            instruction.parameters ~= InstructionParameter(InstructionParameterType.register, get_register_type(this.doublePeek().value));
            current++;

            instructions[current_instruction] = instruction;
            current_instruction++;
            break;
        default:
            exit(-1);
            return;
        }

        current++;
    }

    string to_bin()
    {
        bin = "";

        while (current < this.tokens.length)
        {
            switch (this.tokens[current].type)
            {
            case TokenType.eol, TokenType.eof:
                break;
            case TokenType.instruction:
                this.handleInstruction();
                current++;
                if (current < this.tokens.length
                    && this.tokens[current].type != TokenType.eol
                    && this.tokens[current].type != TokenType.eof)
                {
                    errors ~= "expected newline, got token of type "
                            ~ this.tokens[current].type ~ ": "
                            ~ "'" ~ this.tokens[current].value ~ "'"; 
                }
                break;
            default:
                errors ~= "unexpected token of type "
                        ~ this.tokens[current].type ~ ": "
                        ~ "'" ~ this.tokens[current].value ~ "'";
                break;
            }

            current++;
        }

        return bin;
    }

    void handleInstruction()
    {
        string instruction = this.tokens[current].value;
        switch (instruction)
        {
        case "zero", "inc", "dec", "load", "store":
            if (!this.canPeek())
            {
                errors ~= "insufficient arguments, expected 1 argument: " ~ TokenType.register;
            }
            else if (!is_register(this.peek().value))
            {
                errors ~= "expected register, got token of type "
                        ~ this.peek().type ~ ": "
                        ~ "'" ~ this.peek().value ~ "'";
            }
            else
            {
                bin ~= "000";
                bin ~= register_to_bin(this.peek().value);
                bin ~= this.unary_instruction_funct(instruction);
            }
            break;
        case "inv":
            if (!this.canPeek())
            {
                errors ~= "insufficient arguments, expected 1 argument: " ~ TokenType.register;
            }
            else if (!is_register(this.peek().value))
            {
                errors ~= "expected register, got token of type "
                        ~ this.peek().type ~ ": "
                        ~ "'" ~ this.peek().value ~ "'";
            }
            else
            {
                bin ~= "111";
                bin ~= register_to_bin(this.peek().value);
            }
            break;
        case "brnz", "j", "jal":
            if (!this.canPeek())
            {
                errors ~= "insufficient arguments, expected 1 argument: " ~ TokenType.number;
            }
            else if (this.peek().type != TokenType.number)
            {
                errors ~= "expected number, got token of type "
                        ~ this.peek().type ~ ": "
                        ~ "'" ~ this.peek().value ~ "'";
            }
            else
            {
                string bin_number;
                bool out_of_range;
                if (instruction == "brnz")
                    bin_number = number_to_2s_com_bin(this.peek().value, &out_of_range);
                else
                    bin_number = number_to_bin(this.peek().value, &out_of_range);
                if (out_of_range)
                {
                    errors ~= "number out of range: " ~ this.peek().value;
                }
                else
                {
                    bin ~= this.b_j_instruction_funct(instruction);
                    bin ~= bin_number;
                }
            }
            break;
        case "or", "add", "sub":
            if (!this.canDoublePeek())
            {
                errors ~= "insufficient arguments, expected 2 arguments: " ~ TokenType.register
                        ~ " and " ~ TokenType.register;
            }
            bin ~= this.binary_instruction_funct(instruction);
            bin ~= register_to_bin(this.peek().value);
            bin ~= register_to_bin(this.doublePeek().value);
            current++;
            break;
        default:
            break;
        }

        bin ~= "\n";
        current++;
    }

    string to_hex()
    {
        string[] binary = this.to_bin().split("\n");
        
        string hex = "";
        foreach (string line; binary)
        {
            if (line != "")
            hex ~= bin_to_hex(line) ~ "\n";
        }
        
        return hex;
    }

    string to_logisim()
    {
        string[] binary = this.to_bin().split("\n");
        
        string hex = "v2.0 raw\n";
        foreach (string line; binary)
        {
            if (line != "")
            hex ~= bin_to_hex(line) ~ "\n";
        }
        
        return hex;
    }

    bool canPeek()
    {
        return this.current + 1 < this.tokens.length
                && this.tokens[this.current + 1].type != TokenType.eof
                && this.tokens[this.current + 1].type != TokenType.eol;
    }

    bool canDoublePeek()
    {
        return this.current + 2 < this.tokens.length
                && this.tokens[this.current + 2].type != TokenType.eof
                && this.tokens[this.current + 2].type != TokenType.eol;
    }

    Token peek()
    {
        if (this.current + 1 < this.tokens.length)
            return this.tokens[this.current + 1];

        return Token(TokenType.eof, "");
    }

    Token doublePeek()
    {
        if (this.current + 2 < this.tokens.length)
            return this.tokens[this.current + 2];

        return Token(TokenType.eof, "");
    }

    string unary_instruction_funct(const string instruction)
    {
        switch (instruction)
        {
        case "zero":
            return "000";
        case "inc":
            return "001";
        case "dec":
            return "010";
        case "load":
            return "100";
        case "store":
            return "101";
        default:
            return "";
        }
    }

    string b_j_instruction_funct(const string instruction)
    {
        switch (instruction)
        {
        case "brnz":
            return "001";
        case "j":
            return "010";
        case "jal":
            return "011";
        default:
            return "";
        }
    }

    string binary_instruction_funct(const string instruction)
    {
        switch (instruction)
        {
        case "or":
            return "100";
        case "add":
            return "101";
        case "sub":
            return "110";
        default:
            return "";
        }
    }
}
