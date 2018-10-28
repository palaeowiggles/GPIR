//
//  Type.swift
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

protocol NominalType : HashableByReference {
    var name: String { get }
}

/// Element key to form a key path in GEP and use.
public enum ElementKey : Equatable {
    case index(Int)
    case name(String)
    case value(Use)
}

/// Struct type.
public class StructType : NominalType {
    public typealias Field = (name: String, type: Type)
    public var name: String
    public var fields: [Field]

    public init(name: String, fields: [Field]) {
        self.name = name
        self.fields = fields
    }
}

prefix operator ^

public extension StructType {
    var type: Type {
        return .struct(self)
    }

    static prefix func ^ (type: StructType) -> Type {
        return .struct(type)
    }

    func field(named name: String) -> Field? {
        return fields.first(where: {$0.name == name})
    }

    func elementType(named name: String) -> Type? {
        return field(named: name)?.type
    }

    var elementTypes: [Type] {
        return fields.map {$0.1}
    }

    func elementType(at key: ElementKey) -> Type? {
        guard case .name(let name) = key else { return nil }
        return elementType(named: name)
    }

    func indexOfField(named name: String) -> Int? {
        return fields.index(where: { $0.name == name })
    }
}

/// Enum type.
public class EnumType : NominalType {
    public typealias Case = (name: String, associatedTypes: [Type])
    public var name: String
    public var cases: [Case]

    public init(name: String, cases: [Case]) {
        self.name = name
        self.cases = cases
    }
}

public extension EnumType {
    var type: Type {
        return .enum(self)
    }

    static prefix func ^ (type: EnumType) -> Type {
        return .enum(type)
    }

    func `case`(named name: String) -> Case? {
        return cases.first(where: {$0.name == name})
    }

    func append(_ enumCase: Case) {
        cases.append(enumCase)
    }

    func appendCase(_ name: String, with types: [Type]) {
        cases.append((name: name, associatedTypes: types))
    }
}

/// Type alias.
public class TypeAlias : NominalType {
    public var name: String
    public var type: Type?

    public init(name: String, type: Type? = nil) {
        self.name = name
        self.type = type
    }
}

public extension TypeAlias {
    static prefix func ^ (alias: TypeAlias) -> Type {
        return .alias(alias)
    }

    var isOpaque: Bool {
        return type == nil
    }
}

/// Type of IR values.
public indirect enum Type {
    /// Scalar boolean. Used as condition in control flow instruction.
    case bool
    /// N-ary tuple.
    case tuple([Type])
    /// Struct.
    case `struct`(StructType)
    /// Enum.
    case `enum`(EnumType)
    /// Pointer.
    /// TODO: Consider if we need this.
    case pointer(Type)
    /// Function type
    case function([Type], Type)
    /// Alias type, transparent or opaque.
    case alias(TypeAlias)
    /// Invalid type during type inference, to be eliminated by the verifier.
    case invalid
}

prefix operator *

public extension Type {
    static var void: Type {
        return .tuple([])
    }

    var pointer: Type {
        return .pointer(self)
    }

    static prefix func * (type: Type) -> Type {
        return type.pointer
    }
}

public extension Type {
    var isFirstClass: Bool {
        switch canonical {
        case .tuple, .pointer, .alias: return true
        default: return false
        }
    }

    var isPointer: Bool {
        switch canonical {
        case .pointer(_): return true
        default: return false
        }
    }

    func isPointer(to pointeeType: Type) -> Bool {
        switch canonical {
        case .pointer(pointeeType): return true
        default: return false
        }
    }

    var isVoid: Bool {
        switch canonical {
        case .void: return true
        default: return false
        }
    }

    func conforms(to other: Type) -> Bool {
        return canonical == other.canonical
    }

    var isNotSized: Bool {
        switch canonical {
        case .invalid, .void, .alias: return true
        default: return false
        }
    }
}

public extension Type {
    func elementType(at key: ElementKey) -> Type? {
        switch (unaliased, key) {
        case let (.tuple(tt), .index(i)) where tt.indices.contains(i):
            return tt[i]
        case let (.struct(structTy), .name(_)):
            guard let ty = structTy.elementType(at: key) else { return nil }
            return ty
        case let (.pointer(t), .index(_)),
             let (.pointer(t), .value(_)):
            return t
        default:
            return nil
        }
    }

    func elementType(at keys: [ElementKey]) -> Type? {
        return keys.reduce(self, { acc, key in
            acc.flatMap { $0.elementType(at: key) }
        })
    }
}

public extension Type {
    var canonical: Type {
        switch self {
        case let .tuple(tt): return .tuple(tt.map{$0.canonical})
        case let .pointer(t): return .pointer(t.canonical)
        case let .function(tt, t): return .function(tt.map{$0.canonical}, t.canonical)
        case let .alias(alias): return alias.type?.canonical ?? self
        case .bool, .struct, .enum, .invalid: return self
        }
    }

    var unaliased: Type {
        if case let .alias(alias) = self {
            return alias.type?.unaliased ?? self
        }
        return self
    }
}

extension Type : Equatable {
    public static func ==(lhs: Type, rhs: Type) -> Bool {
        switch (lhs.canonical, rhs.canonical) {
        case (.invalid, .invalid),
             (.bool, .bool):
            return true
        case let (.tuple(ts1), .tuple(ts2)):
            return ts1 == ts2
        case let (.struct(s1), .struct(s2)):
            return s1 === s2
        case let (.enum(s1), .enum(s2)):
            return s1 === s2
        case let (.pointer(t1), .pointer(t2)):
            return t1 == t2
        case let (.function(tt1, t1), .function(tt2, t2)):
            return tt1 == tt2 && t1 == t2
        case let (.alias(a1), .alias(a2)) where a1.isOpaque && a2.isOpaque:
            return a1.name == a2.name
        default:
            return false
        }
    }
}

public extension StructType {
    var isValid: Bool {
        return elementTypes.forAll { $0.isValid }
    }
}

public extension EnumType {
    var isValid: Bool {
        return cases.forAll { $0.associatedTypes.forAll { $0 == ^self || $0.isValid } }
    }
}

public extension Type {
    var isValid: Bool {
        switch self {
        case .invalid:
            return false
        case .bool, .void:
            return true
        case let .pointer(elementType):
            return elementType.isValid
        case let .tuple(elementTypes):
            return elementTypes.forAll { $0.isValid }
        case let .struct(structTy):
            return structTy.isValid
        case let .enum(enumTy):
            return enumTy.isValid
        case let .function(args, ret):
            return args.forAll { $0.isValid } && ret.isValid
        case let .alias(a):
            return a.isValid
        }
    }
}

public extension TypeAlias {
    var isValid: Bool {
        return type?.isValid ?? true
    }
}

public extension Type {
    func makeZero() -> LiteralValue {
        return LiteralValue(type: self, literal: .zero)
    }
}
