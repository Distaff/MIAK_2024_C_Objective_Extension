#include <cstdio>
#include <fstream>
#include <iostream>
#include <exception>

#include "ExtBuilder.h"

extern "C" int yyparse();
extern "C" int yylex();
extern "C" FILE *yyin;
extern "C" int yydebug;

ExtBuilder extBuilder;

/*      Exports      */ 
void reprintTokenPlain(const char *value, int token)    { extBuilder.reprintToken(value, token); };
void setSpecialStatePlain(int token)                    { extBuilder.setSpecialState(token); }
void defineMethodPlain(const char *methodName)          { extBuilder.defineMethod(methodName); }
void defineClassPlain(const char *className)            { extBuilder.defineClass(className); }
void declareObjectPlain(const char *className, const char *objectName)  { extBuilder.declareObject(className, objectName); }
void executeMethodPlain(const char *objectName, const char *methodName) { extBuilder.executeMethod(objectName, methodName); }
void createTypeSpecifierPlain(const char *className)    { extBuilder.createTypeSpecifier(className); }

extern "C" {
    void reprintToken(const char *value, int token) { reprintTokenPlain(value, token); }
    void setSpecialState(int token)                 { setSpecialStatePlain(token); }
    void defineMethod(const char *methodName)       { defineMethodPlain(methodName); }
    void defineClass(const char *className)         { defineClassPlain(className); }
    void declareObject(const char *className, const char *objectName)   { declareObjectPlain(className, objectName); }
    void executeMethod(const char *objectName, const char *methodName)  { executeMethodPlain(objectName, methodName); }
    void createTypeSpecifier(const char *className) { createTypeSpecifierPlain(className); }
}

int main(int argc, char **argv)
{
    std::cout << "C Objective Extensions StS Compiler v0.1\n";

    if(argc < 2 || argc > 4) {
        std::cout << "Usage: cobext [input file] <output file> <-v>\n" \
            "  -v: Enable verbose mode (optional)\n";
        return 1;
    }
    if(std::string(argv[1]) == std::string(argv[2])) {
        std::cerr << "Input and output files must be different!\n";
        return 1;
    }
    yyin = fopen(argv[1], "r");
    if(!yyin) {
        std::cerr << "Failed to open input file!\n";
        return 1;
    }
    std::ofstream outputFile{argv[2]};
    if(!outputFile.is_open()) {
        std::cerr << "Failed to open output file!\n";
        return 1;
    }
    if(argc == 4 && std::string(argv[3]) == "-v") {
        yydebug = 1;
    }

    extBuilder = ExtBuilder(&outputFile, &std::cerr);

    std::cout << "Processing input...\n";

    try {
        auto parseError = yyparse();
        if(parseError || extBuilder.hasErrors()) {
            if(yydebug) {
                std::cerr << "Compilation failed. Tokens dump:\n\n";
                extBuilder.dumpTokens();

                std::cerr << "\n\nExiting.\n";
            }
            else {
                std::cerr << "\nCompilation failed. Exiting.\n";
            }

            return 1;
        }
    }
    catch(const std::exception& e) {
        std::cerr << "\nInternal error: " << e.what() << "\nExiting.\n";
        fclose(yyin);
        outputFile.close();
        return 1;
    }


    fclose(yyin);
    outputFile.close();

    std::cout << "Done.\n";

    return 0;
}