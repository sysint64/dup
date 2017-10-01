module dupt.func;

import dupt.emitter;
import dupt.type;
import std.container.array;
import std.array;
import std.algorithm.searching;

class Argument : IEmittable {
    Type type;
    string name;
    Array!Attribute attributes;

    string emit() {
        auto emitter = new Emitter();
        emitter.emit("$A< > $E $L", attributes, type, name);
        return emitter.build();
    }

    this(in string name, Type type, Array!Attribute attributes) {
        this.name = name;
        this.type = type;
        this.attributes = attributes;
    }

    static Argument create(in string name, in string type, in string attribute = "") {
        return new Argument.Builder()
            .setName(name)
            .setType(Type.createPrimitiveType(type))
            .addAttribute(new Attribute(attribute))
            .build();
    }

    static Argument create(in string name, in string type, in Type.Which which,
                           in string attribute = "")
    {
        return new Argument.Builder()
            .setName(name)
            .setType(Type.createType(name, which))
            .addAttribute(new Attribute(attribute))
            .build();
    }

    static class Builder {
        Type type;
        string name;
        Array!Attribute attributes;

        Builder setName(in string name) {
            this.name = name;
            return this;
        }

        Builder setType(Type type) {
            this.type = type;
            return this;
        }

        Builder addAttribute(Attribute attribute) {
            this.attributes.insert(attribute);
            return this;
        }

        Argument build() {
            return new Argument(name, type, attributes);
        }
    }
}

class Attribute : IEmittable {
    bool isUda = false;
    string name;

    immutable keywordsAttributes = [
        "public", "private", "protected", "package", "override", "auto", "final", "in", "lazy",
        "out", "ref", "return", "scope", "const", "immutable", "inout", "shared"
    ];

    this(in string name) {
        this.name = name;

        if (count(keywordsAttributes, name) == 0) {
            isUda = true;
        }
    }

    string emit() {
        return isUda ? "@" ~ name : name;
    }
}

class Function : IEmittable {
    Type returnType;
    Array!Argument arguments;
    string name;
    string statements;
    Array!Attribute attributes;

    this(in string name, in string statements, Type returnType,
         Array!Argument arguments, Array!Attribute attributes)
    {
        this.returnType = returnType;
        this.arguments = arguments;
        this.attributes = attributes;
        this.name = name;
        this.statements = statements;
    }

    string emit() {
        auto emitter = new Emitter();

        with (emitter) {
            emitln("$A< > $E $L($A) {", attributes, returnType, name, arguments);
            emitln(statements);
            emitln("}");
        }

        return emitter.build();
    }

    static class Builder {
        Type returnType;
        string name;
        Array!Argument arguments;
        Array!Attribute attributes;
        auto emitter = new Emitter();

        Builder setReturnType(Type returnType) {
            this.returnType = returnType;
            return this;
        }

        Builder addArgument(Argument argument) {
            this.arguments.insert(argument);
            return this;
        }

        Builder addAttribute(Attribute attribute) {
            this.attributes.insert(attribute);
            return this;
        }

        Builder addStatement(T...)(in string format, T args) {
            emitter.emitln(format, args);
            return this;
        }

        Builder setName(string name) {
            this.name = name;
            return this;
        }

        Function build() {
            return new Function(name, emitter.build(), returnType, arguments, attributes);
        }
    }

}

unittest {
    import dunit.assertion;
    import std.stdio;

    auto func = new Function.Builder()
        .setName("test")
        .setReturnType(Type.createPrimitiveType("void"))
        .addAttribute(new Attribute("private"))
        .addAttribute(new Attribute("property"))
        .addStatement("writeln(\"Hello world!\");")
        .addArgument(Argument.create("a", "int", "in"))
        .addArgument(Argument.create("b", "int", "in"))
        .build();

    writeln("Function:");
    writeln(func.emit());
}
