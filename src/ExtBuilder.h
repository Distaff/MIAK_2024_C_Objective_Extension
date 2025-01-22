extern "C" {
#include "../build/immediate/y.tab.h"
extern int yylineno;
}

extern "C" const char* getTokenName(int token);

#include <iostream>
#include <exception>
#include <map>
#include <string>
#include <vector>
#include <set>
#include <format>

// UTIL
const char* WS = " \t\n\r\f\v";

inline std::string& rtrim(std::string& s, const char* t = WS)
{
    s.erase(s.find_last_not_of(t) + 1);
    return s;
}
inline std::string& ltrim(std::string& s, const char* t = WS)
{
    s.erase(0, s.find_first_not_of(t));
    return s;
}
inline std::string& trim(std::string& s, const char* t = WS)
{
    return ltrim(rtrim(s, t), t);
}
// UTIL END

struct ClassDef {
    std::string dataDefition;
    std::map<std::string, std::string, std::less<>> methodDefinitions;   // method name -> method code (converted)
};

class ExtBuilder {
private:
    enum {
        STATE_CLASSDEF,
        STATE_CLASSDEF_DATA,
        STATE_CLASSDEF_METHODS,
        STATE_CLDECL,
        STATE_CLEXEC,
        STATE_CLACCESS,
        STATE_CLTYPE,
        STATE_NONE,
    } specialState = STATE_NONE;
    std::string specialStateBuffer_;

    ClassDef currentClassDef;
    std::map<std::string, ClassDef> classDefs_;  // class name -> ClassDef
    std::map<std::string, std::string> objDefs_;  // object name -> class name
    std::vector<int> tokens_;

    std::ostream* out_;
    std::ostream* errout_;
    bool hasError = false;

    inline std::string mangleClassName(const std::string& className) {
        return std::format("__CLASSDEF_{}", className);
    }
    inline std::string mangleMethodName(const std::string& className, const std::string& methodName) {
        return std::format("__METDEF_{}_{}", className, methodName);
    }
    inline void emitError(const std::string& msg) {
        hasError = true;
        *errout_ << std::format("line {}: Object Builder error: \n\t{}\n", yylineno, msg);
    }

public:
    ExtBuilder(std::ostream* out = &std::cout, std::ostream* errout = &std::cerr) : out_(out), errout_(errout) {}
    ExtBuilder& operator=(const ExtBuilder& other)  = default;
    ExtBuilder& operator=(ExtBuilder&& other)       = default;
    ExtBuilder(const ExtBuilder& other)             = default;
    ExtBuilder(ExtBuilder&& other)                  = default;
    ~ExtBuilder()                                   = default;

    bool hasErrors() {
        return hasError;
    }

    void dumpTokens() {
        for(auto token : tokens_) {
            *errout_ << std::format("{} ", getTokenName(token));
        }
    }

    void reprintToken(const std::string& value, int token) {
        if(token)
            tokens_.push_back(token);

        switch(specialState) {
            case STATE_CLASSDEF_DATA:
                currentClassDef.dataDefition += value;
                break;

            case STATE_CLDECL:
            case STATE_CLASSDEF_METHODS:
            case STATE_CLEXEC:
            case STATE_CLTYPE:
                specialStateBuffer_ += value;
                break;

            case STATE_CLASSDEF:
                break;

            default:
                *out_ << value;
                break;
        }
    }
    
    void setSpecialState(int token) {
        switch(token) {
            case CLASSDEF:
                specialState = STATE_CLASSDEF;
                break;
            case CLASSDEF_DATA:
                specialState = STATE_CLASSDEF_DATA;
                break;
            case CLASSDEF_MDEF:
                specialState = STATE_CLASSDEF_METHODS;
                break;
            case CLDECL:
                specialState = STATE_CLDECL;
                break;
            case CLEXEC:
                specialState = STATE_CLEXEC;
                break;
            case CLACCESS:
                specialState = STATE_CLACCESS;
                break;
            case CLTYPE:
                specialState = STATE_CLTYPE;
                break;
            case 0:
                specialState = STATE_NONE;
                break;
            default:
                std::runtime_error("Invalid special state!");
        }
        specialStateBuffer_.clear();
    };

    void defineMethod(std::string methodName) {
        trim(methodName);
        trim(specialStateBuffer_);

        if(currentClassDef.methodDefinitions.find(methodName) != currentClassDef.methodDefinitions.end()) {
            emitError(std::format("Method '{}' already defined!", methodName));
            return;
        }
        if(specialStateBuffer_.empty()) {
            emitError(std::format("Method '{}' definition is empty!", methodName));
            return;
        }

        currentClassDef.methodDefinitions[methodName] = specialStateBuffer_;
    }
    
    void defineClass(std::string className) {
        trim(className);

        if(classDefs_.find(className) != classDefs_.end()) {
            emitError(std::format("Class '{}' already defined!", className));
            return;
        }
        if(currentClassDef.dataDefition.empty() && currentClassDef.methodDefinitions.empty()) {
            emitError(std::format("Class '{}' definition empty!", className));
            return;
        }
        
        classDefs_[className] = currentClassDef;
        *out_ << std::format("typedef struct {} {} {};\n\n", mangleClassName(className), currentClassDef.dataDefition, mangleClassName(className));

        for(auto& [name, definition] : currentClassDef.methodDefinitions) {
            std::size_t namePos = definition.find(name);
            std::size_t argListBegin = definition.find('(', namePos + name.length());

            if(definition[definition.find_first_not_of(WS, argListBegin + 1)] == ')') {
                definition.replace(argListBegin, 1, std::format("({} *this", mangleClassName(className)));
            }
            else {
                definition.replace(argListBegin, 1, std::format("({} *this, ", mangleClassName(className)));
            }

            definition.replace(definition.find(name), name.size(), mangleMethodName(className, name));
            *out_ << std::format("{}\n\n", definition);
        }

        currentClassDef = ClassDef();
    }

    void declareObject(std::string className, std::string objectName) {
        trim(className);
        trim(objectName);

        if(!classDefs_.contains(className)) {
            emitError(std::format("Class '{}' not defined!", className));
            return;
        }

        objDefs_[objectName] = className;
        *out_ << std::format("{} {}", mangleClassName(className), objectName);
    }

    void executeMethod(std::string objectName, std::string methodName) {
        trim(objectName);
        trim(specialStateBuffer_);

        if(!objDefs_.contains(objectName)){
            emitError(std::format("Object '{}' not declared!", objectName));
            return;
        }

        std::string className = objDefs_[objectName];

        if(!classDefs_[className].methodDefinitions.contains(methodName)) {
            emitError(std::format("Method '{}' not defined for class '{}'!", methodName, className));
            return;
        }

        std::string argList = specialStateBuffer_;
        std::string declarator = std::format("{}.{}" , objectName, methodName);

        argList.erase(argList.find(declarator), declarator.size());

        std::size_t argListBegin = argList.find('(');
        if(argList[argList.find_first_not_of(WS, argListBegin + 1)] == ')') {
            argList.replace(argListBegin, 1, std::format("(&{} ", objectName));
        }
        else {
            argList.replace(argListBegin, 1, std::format("(&{}, ", objectName));
        }


        *out_ << std::format("{}{}", mangleMethodName(className, methodName), argList);
    }

    void createTypeSpecifier(std::string className) {
        trim(className);
        trim(specialStateBuffer_);

        if(!classDefs_.contains(className)) {
            emitError(std::format("Class '{}' not defined!", className));
            return;
        }

        specialStateBuffer_.replace(specialStateBuffer_.find(className), className.size(), mangleClassName(className));

        *out_ << specialStateBuffer_;
    }
};

