CC 	= gcc
CXX = g++
FLEX = flex
YACC = yacc

EXEC_NAME = cobext

BUILD_DIR := ./build
SRC_DIR:= ./src


$(EXEC_NAME): $(SRC_DIR)/lexer.l $(SRC_DIR)/parser.y
	mkdir -p $(BUILD_DIR)/autogen
	$(FLEX) -o $(BUILD_DIR)/autogen/lex.yy.c $(SRC_DIR)/lexer.l
	$(YACC) -d --output-file=$(BUILD_DIR)/autogen/y.tab.c -d $(SRC_DIR)/parser.y
	$(CC) -o $(BUILD_DIR)/$(EXEC_NAME) $(BUILD_DIR)/autogen/y.tab.c $(BUILD_DIR)/autogen/lex.yy.c

run: $(BUILD_DIR)/$(EXEC_NAME)
	$(BUILD_DIR)/$(EXEC_NAME)
	

.PHONY: clean
clean:
	rm -r $(BUILD_DIR)


