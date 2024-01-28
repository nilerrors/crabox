module token;

enum TokenType
{
	illegal = "<illegal>",
    eol     = "<eol>",
    eof     = "<eof>",

    instruction = "<instruction>",
    register    = "<register>",
    number      = "<number>",
}

struct Token
{
    TokenType type;
    string value;
}

