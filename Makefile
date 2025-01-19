CC 	= gcc -g
CXX = g++-13 -std=c++23 -g 
FLEX = flex
YACC = bison

EXEC_NAME = cobext

BUILD_DIR := ./build
IMM_DIR := $(BUILD_DIR)/immediate
OBJ_DIR := $(BUILD_DIR)/obj
SRC_DIR:= ./src

all: prep lexer parser $(EXEC_NAME)
	

.PHONY: prep
prep:
	mkdir -p $(BUILD_DIR)
	mkdir -p $(IMM_DIR)
	mkdir -p $(OBJ_DIR)
	
.PHONY: lexer
lexer: $(SRC_DIR)/lexer.l parser prep
	$(FLEX) -o $(IMM_DIR)/lex.yy.c $(SRC_DIR)/lexer.l
	$(CC) -c -o $(OBJ_DIR)/lexer.o $(IMM_DIR)/lex.yy.c
	
.PHONY: parser
parser: $(SRC_DIR)/parser.y prep
	$(YACC) -Wcounterexamples -d --output-file=$(IMM_DIR)/y.tab.c -d $(SRC_DIR)/parser.y
	$(CC) -c -o $(OBJ_DIR)/parser.o $(IMM_DIR)/y.tab.c
	

$(EXEC_NAME): prep lexer parser
	$(CXX) -o $(BUILD_DIR)/$(EXEC_NAME) $(OBJ_DIR)/lexer.o $(OBJ_DIR)/parser.o $(SRC_DIR)/main.cpp

run: all
	$(BUILD_DIR)/$(EXEC_NAME)
	

.PHONY: clean
clean:
	rm -r $(BUILD_DIR)


