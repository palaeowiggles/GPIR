//
//  AlgebraSimplification.swift
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

// TODO: Revisit when scalar numeric types are implemented.
// Without them, we can't do any math simplification.

/// Algebra Simplification simplifies the following expressions
/// 1. Arithmetics
///    * Neutral/absorbing expressions
///       - x + 0 | 0 + x | x - 0 | x * 1 | 1 * x | x / 1 => x
///       - x * 0 | 0 * x => 0
///       - x^0 => 1
///       - x^1 => x
///    * Same argument reduction
///       - x - x => 0
///       - x / x => 1
///    * Strength reduction
///       - x^(-1) => 1 / x
///       - x^2 => x * x
/// 2. Trignometry
///    - (e^x - e^(-x)) / 2 => sinh(x)
///    - (e^x + e^(-x)) / 2 => cosh(x)
///    - (e^x - e^(-x)) / (e^x + e^(-x)) => tanh(x)
///    - sin(0) | sinh(0) => 0
///    - cos(0) | cosh(0) => 1
///    - tan(0) | tanh(0) => 0
/// 3. Reassociation
///    - (e^x)^y => e^(x*y)
///    - e^x / e^y => e^(x-y)
///    - (x / y) / (z / a) => (x * a) / (y * z)
///    - (x / y) / z => x / (y * z)
///    - x / (y / z) => (x * z) / y
/// 4. Linear algebra
///    - (A^T)^T => A
open class AlgebraSimplification : TransformPass {
    public typealias Body = Function

    @discardableResult
    private static func performSimplification(on expr: AlgebraicExpression,
                                              in function: Function,
                                              using builder: IRBuilder,
                                              workList: inout [AlgebraicExpression]) -> Bool {
        /// Pattern-match expressions
        switch expr {
        default:
            return false
        }
    }

    // MARK: - Pass entry
    open class func run(on body: Function) -> Bool {
        var changed = false
        var workList: [AlgebraicExpression] = []
        let builder = IRBuilder(function: body)
        var changedInIter: Bool
        /// Repeat until no changes occur
        repeat {
            changedInIter = false
            /// Repeat
            for bb in body {
                let algExprs = bb.analysis(from: AlgebraicExpressionAnalysis.self)
                for expr in algExprs.expressions {
                    workList.append(expr)
                }
            }
            /// Iterate through the worklist and optimize them
            while let expr = workList.popLast() {
                for expr in expr.transposeTraversed(in: .breadthFirst) where !expr.isAtom {
                    let newlyChanged = performSimplification(on: expr, in: body, using: builder, workList: &workList)
                    changedInIter = changedInIter || newlyChanged
                    if newlyChanged { break }
                }
            }
            changed = changed || changedInIter
        } while changedInIter
        return changed
    }
}
