# C Objective Extenstions (cobext)
## Project Assumptions

### General Program Goals
This compiler makes it easier to write object-oriented code in C by extending C language with basic objecitve features.
As its features are very limited, it's more of a proof-of-concept.

### Compiler Type
Source-to-source compiler - it translates cobext language into pure C.

### Implementation Language
C++, Bison/Lex

### Scanner/Parser Implementation
Parser is auto-generated with Bison.
Lexer is auto-generated with Lex.

## Token Description
New keywords:
```bison
@classdef <CLASS_NAME> {<class definition>}         // class definition
@data {<definiton>}                                 // class internal data fields definition (inside class definition)
@mdef <METHOD_NAME>(<arguments>) {<definiton>}      // method definition (inside class definition)
@cldecl <CLASS_NAME> <OBJECT_NAME>                  // declaration of an object
@clexec <OBJECT_NAME>.<METHOD_NAME>(<arguments>)    // method call
@claccess @claccess <OBJECT_NAME>.<FIELD_NAME>      // access to interal data of an object
@cltype <CLASS_NAME>                                // class type specifier
```

Usage:
```C
@classdef MyClass {    // class definition
    @data {
        int dataField1;     // class internal data fields declared in a struct-like fashion
        float dataField2;
        ...
    }
    
    @mdef method1(int param1) {     // method definition
        this->dataField1 = 0;       // you can use "this" pointer inside method definitions
        ...
    }

    @mdef method2(int param1, param2) {
        ...
    }

    ...
}

void someFunction() {
    @cldecl MyClass MyObj;              // declaration of an object

    @clexec MyObj.method1(10);          // method call
    @claccess MyObj.dataField1 = 50;    // access to interal data of an object
}

void someFuntionTakingObjectAsParameter(@cltype MyClass param1) {   // Use class type specifier to use object as a parameter in a function
    ...
}

typedef @cltype MyClass ClassTypedefed;         // you can use class type specifier also in typedefs
typedef @cltype MyClass* ClassTypedefedPtr;     // you can also use pointers
```

## Format Grammar of extensions
Lexer:
```yacc
"@classdef"             { return CLASSDEF; }
"@data"                 { return CLASSDEF_DATA; }
"@mdef"                 { return CLASSDEF_MDEF; }
"@cldecl"               { return CLDECL; }
"@clexec"               { return CLEXEC; }
"@claccess"             { return CLACCESS; }
"@cltype"               { return CLTYPE; }
```

Parser:
```bison
%token CLASSDEF CLASSDEF_DATA CLASSDEF_MDEF
%token CLDECL CLEXEC CLACCESS CLTYPE

ext_method_definition
	: CLASSDEF_MDEF declaration_specifiers IDENTIFIER '(' parameter_type_list ')' compound_statement
	| CLASSDEF_MDEF declaration_specifiers IDENTIFIER '(' ')' compound_statement
	;

ext_method_definition_list
	: ext_method_definition
	| ext_method_definition_list ext_method_definition
	;

ext_class_data
	: CLASSDEF_DATA '{' struct_declaration_list '}' { setSpecialState(CLASSDEF); }
	;

ext_class_definition
	: CLASSDEF IDENTIFIER '{' ext_class_data ext_method_definition_list '}'
	| CLASSDEF IDENTIFIER '{' ext_class_data '}'
	;

ext_class_object_declaration
	: CLDECL IDENTIFIER IDENTIFIER { declareObject($2, $3); setSpecialState(0); };
	;

ext_class_method_execution_expression
	: CLEXEC IDENTIFIER '.' IDENTIFIER '(' argument_expression_list ')'
	| CLEXEC IDENTIFIER '.' IDENTIFIER '(' ')'		
	;

ext_class_access_expression
	: CLACCESS IDENTIFIER '.' IDENTIFIER
	;

ext_class_type_specifier
	: CLTYPE pointer IDENTIFIER
	| CLTYPE IDENTIFIER
	;
```
The rest of the lexer rules can be found in /src/lexer.l. \
Full grammar can be found in /src/parser.y

## Used Generators and External Packages
1. Bison
    - Parser generator
    - Used to generate parser for the cobext language
2. Flex
    - Lexer generator
    - Used to generate lexer for the cobext language
2. C++
    - Implementation language
    - C++23 standard has beed used
3. Make
    - Build automation tool

## User Manual
1. Install required packages:
```bash
sudo apt-get install bison flex g++ make
```
Keep in mind that you need GCC with C++23 support (verison >= 14.0).

3. Build the compiler:
```bash
make all
```

4. Run the compiler:
```bash
./build/cobext cobext [input file] [output file] <-v>
```
Use -v flag to enable verbose mode (prints trace messages during parsing, list of tokens, etc.).

5. Try to compile generated code:
```bash
gcc -o [output binary] [output file from cobext]
```
## Usage Examples
Usage examples can be found in /examples/ directory.


## Additional Information
- The compiler is very limited and is more of a proof-of-concept. Only basic functionality is supported - no inheritance, no polymorphism, no access modifiers, etc.
- It is designed to be used after the C preprocessor, so it doesn't support preprocessor directives.
    - Currently, all preprocessor directives are ignored and passed to the output file without processing.
    - This means that when compiling directly, you cannot mix cobext code with preprocessor directives, and cannot use cobext code in header files.
    - If you want to use preprocessor directives, you should first run the C preprocessor on the input file and then run the cobext compiler on the preprocessed file eg.:
    ```bash
    gcc -E input.cobext -o input_preprocessed.cobext
    ./build/cobext input_preprocessed.cobext output.c
    gcc -o output.out output.c
    ```
