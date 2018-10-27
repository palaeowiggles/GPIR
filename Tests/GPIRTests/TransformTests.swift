//
//  TransformTests.swift
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

class TransformTests : XCTestCase {
    let builder = IRBuilder(moduleName: "TransformTest")

    /// - TODO: Fix bug in dominance analysis that causes crash
    func testDCE() throws {
        let fun = builder.buildFunction(
            named: "bar",
            argumentTypes: [.bool],
            returnType: .bool)
        let entry = builder.buildEntry(argumentNames: ["x", "y"], in: fun)
        builder.move(to: entry)
        let cond = builder.boolean(.and,
            .literal(.bool, true), %entry.arguments[0])
        let dead1 = builder.buildInstruction(
            .booleanBinary(.and,
                           .literal(.bool, true),
                           .literal(.bool, false)), name: "dead1")
        builder.buildInstruction(.booleanBinary(
            .or, %dead1, false ~ .bool), name: "dead2")
        let thenBB = builder.buildBasicBlock(
            named: "then", arguments: ["a" : .bool], in: fun)
        let elseBB = builder.buildBasicBlock(
            named: "else", arguments: ["b" : .bool], in: fun)
        let contBB = builder.buildBasicBlock(
            named: "cont", arguments: ["c" : .bool], in: fun)
        builder.conditional(%cond,
                            then: thenBB, arguments: [.literal(.bool, true)],
                            else: elseBB, arguments: [.literal(.bool, false)])
        builder.move(to: thenBB)
        builder.branch(contBB, [ %thenBB.arguments[0] ])
        builder.move(to: elseBB)
        builder.branch(contBB, [ %elseBB.arguments[0] ])
        builder.move(to: contBB)
        builder.return(%contBB.arguments[0])

        /// Original:
        /// func @bar: (bool) -> bool {
        /// 'entry(%x: bool):
        ///     %0.0 = and true: bool, %x: bool
        ///     %dead1 = and true: bool, false: bool
        ///     %dead2 = or %dead1: bool, false: bool
        ///     conditional %0.0: bool then 'then(true: bool) else 'else(false: bool)
        /// 'then(%a: bool):
        ///     branch 'cont(%a: bool)
        /// 'else(%b: bool):
        ///     branch 'cont(%b: bool)
        /// 'cont(%c: bool):
        ///     return %c: bool
        /// }

        let module = builder.module
        module.mapTransform(DeadCodeElimination.self)
        let after = """
            func @bar: (bool) -> bool {
            'entry(%x: bool):
                %0.0 = and true: bool, %x: bool
                conditional %0.0: bool then 'then(true: bool) else 'else(false: bool)
            'then(%a: bool):
                branch 'cont(%a: bool)
            'else(%b: bool):
                branch 'cont(%b: bool)
            'cont(%c: bool):
                return %c: bool
            }
            """
        XCTAssertEqual(fun.description, after)

        /// Reapplying shouldn't mutate the function
        XCTAssertFalse(module.mapTransform(DeadCodeElimination.self))
    }

    func testCSE() throws {
        let fun = builder.buildFunction(named: "bar",
                                        argumentTypes: [.bool, .bool],
                                        returnType: .bool)
        let entry = builder.buildEntry(argumentNames: ["x", "y"], in: fun)
        builder.move(to: entry)
        let common1 = builder.boolean(.or, %entry.arguments[0], %entry.arguments[1])
        let common2 = builder.boolean(.or, %entry.arguments[0], %entry.arguments[1])
        let common3 = builder.boolean(.and, %common1, .literal(.bool, true))
        let common4 = builder.boolean(.and, %common2, .literal(.bool, true))
        let common5 = builder.boolean(.or, %common3, .literal(.bool, false))
        let common6 = builder.boolean(.or, %common4, .literal(.bool, false))
        let cond = builder.boolean(.and, %common5, %common6)
        let thenBB = builder.buildBasicBlock(
            named: "then", arguments: ["a" : .bool], in: fun)
        let elseBB = builder.buildBasicBlock(
            named: "else", arguments: ["b" : .bool], in: fun)
        let contBB = builder.buildBasicBlock(
            named: "cont", arguments: ["c" : .bool], in: fun)
        builder.conditional(%cond,
                            then: thenBB, arguments: [.literal(.bool, true)],
                            else: elseBB, arguments: [.literal(.bool, false)])
        builder.move(to: thenBB)
        let notCommon1 = builder.boolean(.or,
            .literal(.bool, true), .literal(.bool, false))
        builder.branch(contBB, [%notCommon1])
        builder.move(to: elseBB)
        let notCommon2 = builder.boolean(.or,
            .literal(.bool, true), .literal(.bool, false))
        builder.branch(contBB, [%notCommon2])
        builder.move(to: contBB)
        let common7 = builder.boolean(.or, %common3, .literal(.bool, false))
        let result = builder.boolean(.and, %common7, %contBB.arguments[0])
        builder.return(%result)

        /// Original:
        /// func @bar: (bool, bool) -> bool {
        /// 'entry(%x: bool, %y: bool):
        ///     %0.0 = or %x: bool, %y: bool
        ///     %0.1 = or %x: bool, %y: bool
        ///     %0.2 = and %0.0: bool, true: bool
        ///     %0.3 = and %0.1: bool, true: bool
        ///     %0.4 = or %0.2: bool, false: bool
        ///     %0.5 = or %0.3: bool, false: bool
        ///     %0.6 = and %0.4: bool, %0.5: bool
        /// conditional %0.6: bool then 'then(true: bool) else 'else(false: bool)
        ///     'then(%a: bool):
        ///     %1.0 = or true: bool, false: bool
        ///     branch 'cont(%1.0: bool)
        /// 'else(%b: bool):
        ///     %2.0 = or true: bool, false: bool
        ///     branch 'cont(%2.0: bool)
        /// 'cont(%c: bool):
        ///     %3.0 = or %0.2: bool, false: bool
        ///     %3.1 = and %3.0: bool, %c: bool
        ///     return %3.1: bool
        /// }

        let module = builder.module
        module.mapTransform(CommonSubexpressionElimination.self)
        let after = """
            func @bar: (bool, bool) -> bool {
            'entry(%x: bool, %y: bool):
                %0.0 = or %x: bool, %y: bool
                %0.1 = and %0.0: bool, true: bool
                %0.2 = or %0.1: bool, false: bool
                %0.3 = and %0.2: bool, %0.2: bool
                conditional %0.3: bool then 'then(true: bool) else 'else(false: bool)
            'then(%a: bool):
                %1.0 = or true: bool, false: bool
                branch 'cont(%1.0: bool)
            'else(%b: bool):
                %2.0 = or true: bool, false: bool
                branch 'cont(%2.0: bool)
            'cont(%c: bool):
                %3.0 = and %0.2: bool, %c: bool
                return %3.0: bool
            }
            """
        XCTAssertEqual(fun.description, after)

        /// Reapplying shouldn't mutate the function
        XCTAssertFalse(module.mapTransform(CommonSubexpressionElimination.self))
    }

    /*
    func testAlgebraSimplification() {
        let fun = builder.buildFunction(named: "foo",
                                        argumentTypes: [.bool],
                                        returnType: .bool)
        let entry = builder.buildEntry(argumentNames: ["x"], in: fun)
        builder.move(to: entry)

        /// Arithmetics
        /// Neutral/absorbing expressions
        let x = %entry.arguments[0]
        /// x + 0 | 0 + x | x - 0 | x * 1 | 1 * x | x / 1 => x
        let a0 = builder.add(x, .literal(.int(32), 0))
        let a1 = builder.add(.literal(.int(32), 0), %a0)
        let a2 = builder.subtract(%a1, .literal(.int(32), 0))
        let a3 = builder.multiply(%a2, .literal(.int(32), 1))
        let a4 = builder.multiply(.literal(.int(32), 1), %a3)
        let a5 = builder.divide(%a4, .literal(.int(32), 1))
        /// x * 0 | 0 * x => 0
        let b0 = builder.multiply(x, .literal(.int(32), 0))
        let b1 = builder.multiply(%b0, x)
        let b2 = builder.add(%b1, %a5)
        /// x^0 => 1
        /// x^1 => x
        let c0 = builder.power(%b2, .literal(.int(32), 0))
        let c1 = builder.power(%b2, %c0)

        /// Same argument reduction
        /// x - x => 0
        let d0 = builder.subtract(x, x)
        /// x / x => 1
        let d1 = builder.divide(x, x)
        let d2 = builder.multiply(%d0, %d1)
        let d3 = builder.add(%c1, %d2)

        builder.return(%d3)

        let module = builder.module
        module.mapTransform(AlgebraSimplification.self)
        let after = """
            func @foo: (i32) -> i32 {
            'entry(%x: i32):
                return %x: i32
            }
            """
        XCTAssertEqual(fun.description, after)

        /// Reapplying shouldn't mutate the function
        XCTAssertFalse(module.mapTransform(AlgebraSimplification.self))
    }
    */

    func testCFGCanonicalization() {
        /// Test merging multiple exits and forming join blocks
        let fun = builder.buildFunction(named: "foo",
                                        argumentTypes: [.bool],
                                        returnType: .bool)
        let entry = builder.buildEntry(argumentNames: ["x"], in: fun)
        builder.move(to: entry)
        let thenBB = builder.buildBasicBlock(
            named: "then", arguments: [:], in: fun)
        let elseBB = builder.buildBasicBlock(
            named: "else", arguments: [:], in: fun)
        builder.conditional(%entry.arguments[0],
                            then: thenBB, arguments: [],
                            else: elseBB, arguments: [])
        builder.move(to: thenBB)
        let cmp = builder.boolean(.and, %entry.arguments[0], .literal(.bool, true))
        let nestedThenBB = builder.buildBasicBlock(
            named: "nested_then", arguments: [:], in: fun)
        let nestedElseBB = builder.buildBasicBlock(
            named: "nested_else", arguments: [:], in: fun)
        builder.conditional(%cmp,
                            then: nestedThenBB, arguments: [],
                            else: nestedElseBB, arguments: [])
        builder.move(to: nestedThenBB)
        builder.return(.literal(.bool, true))
        builder.move(to: nestedElseBB)
        builder.return(.literal(.bool, true))
        builder.move(to: elseBB)
        builder.return(.literal(.bool, false))

        fun.applyTransform(CFGCanonicalization.self)
        let after = """
            func @foo: (bool) -> bool {
            'entry(%x: bool):
                conditional %x: bool then 'then() else 'else()
            'then():
                %1.0 = and %x: bool, true: bool
                conditional %1.0: bool then 'nested_then() else 'nested_else()
            'else():
                branch 'exit(false: bool)
            'nested_then():
                branch 'then_join(true: bool)
            'nested_else():
                branch 'then_join(true: bool)
            'then_join(%5^0: bool):
                branch 'exit(%5^0: bool)
            'exit(%exit_value: bool):
                return %exit_value: bool
            }
            """
        XCTAssertEqual(fun.description, after)
    }

    static var allTests: [(String, (TransformTests) -> () throws -> Void)] {
        return [
            ("testDCE", testDCE),
            ("testCSE", testCSE),
            // ("testAlgebraSimplification", testAlgebraSimplification),
            ("testCFGCanonicalization", testCFGCanonicalization)
        ]
    }
}
