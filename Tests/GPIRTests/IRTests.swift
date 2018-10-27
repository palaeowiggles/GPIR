//
//  IRTests.swift
//  GPIR
//
//  Copyright 2018 The GPIR Team.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import XCTest
@testable import GPIR

class IRTests : XCTestCase {
    let builder = IRBuilder(moduleName: "IRTest")

    lazy var struct1 = builder.buildStruct(
        named: "TestStruct1", fields: [
            "foo" : .bool,
        ])

    lazy var struct1Global =
        builder.buildVariable(named: "struct1", valueType: struct1.type)

    var enum1: EnumType {
        let tmp = builder.buildEnum(
            named: "TestEnum1",
            cases: ["foo" : [.bool, .bool], "bar" : []])
        tmp.appendCase("baz", with: [.enum(tmp), .bool, .enum(tmp)])
        return tmp
    }

    lazy var enum1Global: Variable =
        builder.buildVariable(named: "enum1", valueType: enum1.type)

    func testInitializeStruct() {
        let structLit: Literal = .struct([
            ("foo", true ~ .bool),
            ("bar", false ~ .bool),
        ])
        let fun = builder.buildFunction(named: "initialize_struct1",
                                        argumentTypes: [],
                                        returnType: .void)
        builder.move(to: builder.buildEntry(argumentNames: [], in: fun))
        _ = builder.literal(structLit, .struct(struct1))
        builder.return()
        XCTAssertEqual(fun.description, """
            func @initialize_struct1: () -> () {
            'entry():
                %0.0 = literal {#foo = true: bool, #bar = false: bool}: $TestStruct1
                return
            }
            """)
    }

    func testInitializeEnum() {
        let fun = builder.buildFunction(named: "initialize_enum1",
                                        argumentTypes: [],
                                        returnType: .void)
        builder.move(to: builder.buildEntry(argumentNames: [], in: fun))
        let enumInst1 = builder.literal(
            .enumCase("foo", [
                .literal(.bool, true), .literal(.bool, false)
            ]), .enum(enum1))
        let undefined = builder.literal(.undefined, .enum(enum1))
        let enumInst2 = builder.literal(.enumCase("bar", []), .enum(enum1))
        _ = builder.literal(
            .enumCase("baz", [
                %enumInst1, %undefined, %enumInst2
            ]), .enum(enum1))
        builder.return()
        XCTAssertEqual(fun.description, """
            func @initialize_enum1: () -> () {
            'entry():
                %0.0 = literal ?foo(true: bool, false: bool): $TestEnum1
                %0.1 = literal undefined: $TestEnum1
                %0.2 = literal ?bar(): $TestEnum1
                %0.3 = literal ?baz(%0.0: $TestEnum1, %0.1: $TestEnum1, %0.2: $TestEnum1): $TestEnum1
                return
            }
            """)
    }

    func testWriteGlobal() {
        let val1 = builder.buildVariable(named: "one", valueType: .bool)
        XCTAssertEqual("\(val1)", "var @one: bool")
        let val2 = builder.buildVariable(named: "two", valueType: *.bool)
        XCTAssertEqual("\(val2)", "var @two: *bool")
    }

    func testWriteStruct() {
        XCTAssertEqual(struct1.description, """
            struct $TestStruct1 {
                #foo: bool
            }
            """)
        XCTAssertEqual("\(struct1Global)", "var @struct1: $TestStruct1")
    }

    func testWriteEnum() {
        XCTAssertEqual(enum1.description, """
            enum $TestEnum1 {
                ?foo(bool, bool)
                ?bar()
                ?baz($TestEnum1, bool, $TestEnum1)
            }
            """)
        XCTAssertEqual("\(enum1Global)", "var @enum1: $TestEnum1")
    }

    func testWriteSimpleFunction() {
        let fun = builder.buildFunction(named: "foo",
                                        argumentTypes: [.bool, .bool],
                                        returnType: .bool)
        let entry = builder.buildEntry(argumentNames: ["x", "y"], in: fun)
        builder.move(to: entry)
        let and = builder.boolean(.and, .literal(.bool, true), %entry.arguments[0])
        let or = builder.boolean(.or, %and, %entry.arguments[1])
        builder.return(%or)
        XCTAssertEqual(fun.description, """
            func @foo: (bool, bool) -> bool {
            'entry(%x: bool, %y: bool):
                %0.0 = and true: bool, %x: bool
                %0.1 = or %0.0: bool, %y: bool
                return %0.1: bool
            }
            """)
    }

    func testWriteMultiBBFunction() {
        let fun = builder.buildFunction(named: "bar",
                                        argumentTypes: [.bool, .bool],
                                        returnType: .bool)
        let entry = builder.buildEntry(argumentNames: ["x", "y"], in: fun)
        builder.move(to: entry)
        let cmp = builder.boolean(.and, %entry.arguments[0], %entry.arguments[1])
        let thenBB = builder.buildBasicBlock(named: "then", arguments: [ "x" : .bool ], in: fun)
        let elseBB = builder.buildBasicBlock(named: "else", arguments: [ "x" : .bool ], in: fun)
        let contBB = builder.buildBasicBlock(named: "cont", arguments: [ "x" : .bool ], in: fun)
        builder.conditional(%cmp, then: thenBB, arguments: [.literal(.bool, true)],
                            else: elseBB, arguments: [.literal(.bool, false)])
        builder.move(to: thenBB)
        builder.branch(contBB, [ %thenBB.arguments[0] ])
        builder.move(to: elseBB)
        builder.branch(contBB, [ %elseBB.arguments[0] ])
        builder.move(to: contBB)
        builder.return(%contBB.arguments[0])
        XCTAssertEqual(fun.description, """
            func @bar: (bool, bool) -> bool {
            'entry(%x: bool, %y: bool):
                %0.0 = and %x: bool, %y: bool
                conditional %0.0: bool then 'then(true: bool) else 'else(false: bool)
            'then(%x: bool):
                branch 'cont(%x: bool)
            'else(%x: bool):
                branch 'cont(%x: bool)
            'cont(%x: bool):
                return %x: bool
            }
            """)
    }

    static var allTests: [(String, (IRTests) -> () throws -> Void)] {
        return [
            ("testInitializeStruct", testInitializeStruct),
            ("testInitializeEnum", testInitializeEnum),
            ("testWriteGlobal", testWriteGlobal),
            ("testWriteStruct", testWriteStruct),
            ("testWriteEnum", testWriteEnum),
            ("testWriteSimpleFunction", testWriteSimpleFunction),
            ("testWriteMultiBBFunction", testWriteMultiBBFunction)
        ]
    }
}
