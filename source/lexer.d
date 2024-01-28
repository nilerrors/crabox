module lexer;

import std.stdio;

import token;
import instruction;
import register;


struct Lexer
{
    Token[] tokens;
    string source;
    int current;

    this(const string source)
    {
        this.source = source;
        this.current = 0;
    }

    Token[] lex()
    {
        while (current < source.length)
        {
            switch(source[current])
            {
            case '\n':
                tokens ~= Token(TokenType.eol, "\n");
                break;
            case ' ':
                break;
            case 'a': .. case 'z':
                string value = "";
                while ((source[current] >= 'a' && source[current] <= 'z') ||
                        (source[current] >= '0' && source[current] <= '9'))
                {
                    value ~= source[current];
                    current++;
                    if (current >= source.length) break;
                }
                current--;
                if (is_register(value))
                    tokens ~= Token(TokenType.register, value);
                else if (is_instruction(value))
                    tokens ~= Token(TokenType.instruction, value);
                else
                    tokens ~= Token(TokenType.illegal, value);
                break;
            case '0': .. case '9':
                string value = "";
                while (source[current] >= '0' && source[current] <= '9')
                {
                    value ~= source[current];
                    current++;
                    if (current >= source.length) break;
                }
                tokens ~= Token(TokenType.number, value);
                break;
            case '-':
            	string value = "-";
            	current++;
                while (source[current] >= '0' && source[current] <= '9')
                {
                    value ~= source[current];
                    current++;
                    if (current >= source.length) break;
                }
                tokens ~= Token(TokenType.number, value);
                break;
            default:
                string value;
                value ~= source[current];
                tokens ~= Token(TokenType.illegal, value);
                break;
            }

            current++;
        }

        tokens ~= Token(TokenType.eof, "");

        return this.tokens;
    }
}

