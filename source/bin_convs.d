module bin_convs;

import std.conv;
import std.format;
import std.array;
import std.range;
import std.stdio;


string reverseString(string str)
{
    string reversed = "";
    foreach (char c; str)
    {
        reversed = c ~ reversed;
    }
    return reversed;
}

string toBinary(int num, int numBits)
{
    string binary = "";
    while (num > 0)
    {
        binary ~= to!string(num % 2);
        num /= 2;
    }
    while (binary.length < numBits)
    {
        binary ~= "0";
    }
    return reverseString(binary);
}

bool is_6bit_2s_complement(string numStr)
{
    int minNum = - 2^^(6 - 1);
    int maxNum = 2^^(6 - 1) - 1;
    int num = to!int(numStr);
    return num >= minNum && num <= maxNum;
}

bool is_6bit_unsigned(string numStr)
{
    int minNum = 0;
    int maxNum = 2^^(6) - 1;
    int num = to!int(numStr);
    return num >= minNum && num <= maxNum;
}

string number_to_2s_com_bin(string numStr, bool *outOfRange, int maxNum = 31, int minNum = -32) {
    int num = to!int(numStr);

    *outOfRange = num < minNum || num > maxNum;
    if (*outOfRange)
        return "";

    if (num < 0)
    {
        num = -num;
        num = (maxNum - minNum) - num;
        num += 1;
    }

    string binary = toBinary(num, 6);
    if (binary.length != 6)
    {
        binary = binary[binary.length - 5 .. $];
    }

    return binary;
}

string number_to_bin(string numStr, bool *outOfRange, int maxNum = 63)
{
    int num = to!int(numStr);

    *outOfRange = num < 0 || num > maxNum;
    if (*outOfRange)
        return "";

    string binary = toBinary(num, 6);
    if (binary.length != 6)
    {
        binary = binary[binary.length - 5 .. $];
    }

    return binary;
}

string bin_half_byte_to_hex_char(const string bin)
{
    switch (bin)
    {
        case "0000":
            return "0";
        case "0001":
            return "1";
        case "0010":
            return "2";
        case "0011":
            return "3";
        case "0100":
            return "4";
        case "0101":
            return "5";
        case "0110":
            return "6";
        case "0111":
            return "7";
        case "1000":
            return "8";
        case "1001":
            return "9";
        case "1010":
            return "a";
        case "1011":
            return "b";
        case "1100":
            return "c";
        case "1101":
            return "d";
        case "1110":
            return "e";
        case "1111":
            return "f";
        default:
            return "0";
    }
}


string[] divide_by_length(const string text, const ulong length)
{
	string[] divisions;

	for (ulong i = 0; i < text.length; i += length)
	{
		if (i + length <= text.length)
			divisions ~= text[i .. i + length];
		else
			divisions ~= text[i .. $];
	}

	return divisions;
}

string bin_to_hex(const string bin)
{
	const NIBBLE_LENGTH = 4;

    string hex = "";
    string[] nibbles = 
    			divide_by_length("0".repeat(NIBBLE_LENGTH - bin.length % NIBBLE_LENGTH).join() ~ bin, NIBBLE_LENGTH);

    foreach (string nibble; nibbles)
    {
    	hex ~= bin_half_byte_to_hex_char(nibble);
    }

    return hex;
}
