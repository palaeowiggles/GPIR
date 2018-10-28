//
//  Literal.swift
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

/// Scalar or tensor literal, literally
/// - Note: It has no type or shape, because a `Literal` is not a `Value`.
/// But `LiteralValue`, that uses `Literal`, is a value.
public indirect enum Literal {
    case undefined
    case null
    case zero
    case bool(BooleanLiteralType)
    case tuple([Use])
    case `struct`([(String, Use)])
    case enumCase(String, [Use])
    // TODO: Add constant expression.
}

extension Literal : Equatable {
    public static func == (lhs: Literal, rhs: Literal) -> Bool {
        switch (lhs, rhs) {
        case (.zero, .zero),
             (.undefined, .undefined),
             (.null, .null):
            return true
        case let (.bool(b1), .bool(b2)):
            return b1 == b2
        case let (.tuple(tt1), .tuple(tt2)):
            return tt1 == tt2
        case let (.struct(ss1), .struct(ss2)):
            return ss1.elementsEqual(ss2, by: { $0 == $1 })
        case let (.enumCase(n1, tt1), .enumCase(n2, tt2)):
            return n1 == n2 && tt1.elementsEqual(tt2, by: { $0 == $1 })
        default: return false
        }
    }
}

// MARK: - Literal conversion


extension Literal : ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: BooleanLiteralType) {
        self = .bool(value)
    }
}

extension Literal : ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self = .null
    }
}

// MARK: - Literal as value

/// Literal value. It wraps `Literal` into a value
public struct LiteralValue : Value {
    public var type: Type
    public var literal: Literal

    public init(type: Type, literal: Literal) {
        self.type = type
        self.literal = literal
    }

    public func makeUse() -> Use {
        return .literal(type, literal)
    }
}

extension LiteralValue : Equatable {
    public static func == (lhs: LiteralValue, rhs: LiteralValue) -> Bool {
        return lhs.type == rhs.type
            && lhs.literal == rhs.literal
    }
}

public extension Literal {
    func substituting(_ new: Use, for old: Use) -> Literal {
        let condSubst = {$0 == old ? new : $0}
        switch self {
        case .tuple(let vv): return .tuple(vv.map(condSubst))
        case .struct(let fields):
            return .struct(Array(fields.map{($0.0, condSubst($0.1))}))
        case let .enumCase(name, associatedTypes):
            return .enumCase(name, associatedTypes.map(condSubst))
        case .null, .undefined, .zero, .bool: return self
        }
    }

    var isAggregate: Bool {
        switch self {
        case .tuple, .struct, .enumCase:
            return true
        default:
            return false
        }
    }

    static func ~= (pattern: IntegerLiteralType, literal: Literal) -> Bool {
        switch literal {
        case .zero where pattern == 0:
            return true
        default:
            return false
        }
    }

    static func ~= (pattern: FloatLiteralType, literal: Literal) -> Bool {
        switch (pattern, literal) {
        case (0.0, .zero): return true
        default: return false
        }
    }
}

public extension Use {
    private static func anyLiteral(from use: Use) -> Literal? {
        switch use {
        case let .literal(_, lit):
            return lit
        case let .definition(.instruction(inst)):
            guard case let .literal(lit, _) = inst.kind else { return nil }
            return lit
        default:
            return nil
        }
    }

    static func ~= (pattern: IntegerLiteralType, use: Use) -> Bool {
        guard let lit = anyLiteral(from: use) else { return false }
        return pattern ~= lit
    }

    static func ~= (pattern: FloatLiteralType, use: Use) -> Bool {
        guard let lit = anyLiteral(from: use) else { return false }
        return pattern ~= lit
    }
}

public extension Value {
    /// Make a literal of the same type
    func makeLiteral(_ literal: Literal, using builder: IRBuilder) -> Value {
        if case .bool = type {
            return LiteralValue(type: type, literal: literal)
        }
        return builder.literal(literal, type)
    }
}

public extension Use {
    func makeLiteral(_ literal: Literal, using builder: IRBuilder) -> Value {
        return value.makeLiteral(literal, using: builder)
    }
}
