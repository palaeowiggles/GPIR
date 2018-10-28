//
//  Op.swift
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

// MARK: - Data type

public enum FloatingPointSize : UInt {
    case half = 16
    case single = 32
    case double = 64
}

extension FloatingPointSize : Comparable {
    public static func <(lhs: FloatingPointSize, rhs: FloatingPointSize) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

public enum DataType : Equatable {
    public enum Base : Int { case bool, int, float }
    case bool
    case int(UInt)
    case float(FloatingPointSize)
}

public extension DataType.Base {
    var isNumeric: Bool {
        return self != .bool
    }
}

public extension DataType {
    var base: Base {
        switch self {
        case .bool: return .bool
        case .int: return .int
        case .float: return .float
        }
    }

    static func ~(lhs: DataType, rhs: DataType) -> Bool {
        return lhs.base == rhs.base
    }

    var isNumeric: Bool {
        return base.isNumeric
    }

    var isBool: Bool {
        return base == .bool
    }

}

public extension DataType {
    func canCast(to other: DataType) -> Bool {
        switch (self, other) {
        case (.bool, .bool): return true
        case let (.int(w1), .int(w2)): return w1 <= w2
        case let (.float(w1), .float(w2)): return w1 <= w2
        default: return false
        }
    }
}

public extension DataType {
    var bitCount: UInt {
        switch self {
        case .bool: return 1
        case .int(let size): return size
        case .float(let size): return size.rawValue
        }
    }
}

// MARK: - Operator definitions

/// Unary op definition
public enum NumericUnaryOp {
    case sinh, cosh, tanh, log, exp, negate, sign, square, sqrt
    case round, rsqrt, ceil, floor
    case tan, cos, sin, acos, asin, atan
    case lgamma, digamma, erf, erfc, rint
}

/// Comparison op definition
public enum ComparisonOp {
    case lessThan, lessThanOrEqual
    case greaterThan, greaterThanOrEqual
    case equal, notEqual
}

/// Boolean op definition
public enum BooleanOp {
    case and, or
}

/// Numeric associative op definition
public enum NumericBinaryOp {
    case add, subtract, multiply, divide, min, max
    case truncateDivide, floorDivide, modulo, power
}

/// Boolean associative op definition
public enum BooleanBinaryOp {
    case and, or
}
