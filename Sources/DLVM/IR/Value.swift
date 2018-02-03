//
//  Value.swift
//  DLVM
//
//  Copyright 2016-2018 The DLVM Team.
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

import CoreTensor
@_exported import CoreOp

/// Value base
public protocol Value : Verifiable {
    var type: Type { get }
    func makeUse() -> Use
}

/// % operator turns a def to a use
prefix operator %

public extension Value {
    prefix static func % (value: Self) -> Use {
        return value.makeUse()
    }

    prefix static func % (value: Value) -> Use {
        return value.makeUse()
    }
}

/// Anything that has a name
public protocol Named {
    var name: String { get }
}

/// A named value
public protocol NamedValue : Value {
    var name: String? { get }
}

/// User, anything that can use a value
public protocol User {
    var operands: [Use] { get }
}

/// Definition
public enum Definition : Hashable, NamedValue {
    case argument(Argument)
    case function(Function)
    case instruction(Instruction)
    case variable(Variable)
}

public extension Definition {
    var type: Type {
        get {
            switch self {
            case .argument(let x):
                return x.type
            case .instruction(let x):
                return x.type
            case .variable(let x):
                return x.type
            case .function(let x):
                return x.type
            }
        }
        set {
            switch self {
            case let .argument(x):
                self = .argument(x)
            case let .instruction(x):
                self = .instruction(x)
            case let .variable(x):
                self = .variable(x)
            case let .function(x):
                self = .function(x)
            }
        }
    }

    var name: String? {
        switch self {
        case .argument(let x):
            return x.name
        case .instruction(let x):
            return x.name
        case .variable(let x):
            return x.name
        case .function(let x):
            return x.name
        }
    }

    public func makeUse() -> Use {
        switch self {
        case .argument(let x): return x.makeUse()
        case .instruction(let x): return x.makeUse()
        case .variable(let x): return x.makeUse()
        case .function(let x): return x.makeUse()
        }
    }

    public func performVerification() throws {
        switch self {
        case .argument(let x): try x.performVerification()
        case .instruction(let x): try x.performVerification()
        case .variable(let x): try x.performVerification()
        case .function(let x): try x.performVerification()
        }
    }
}
