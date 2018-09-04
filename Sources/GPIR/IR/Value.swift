//
//  Value.swift
//  GPIR
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

/// Named value
public protocol NamedValue : Value, AnyObject {
    var name: String? { get }
}

/// User, anything that can use a value
public protocol User {
    var operands: [Use] { get }
}

/// Definition
public enum Definition : Hashable {
    case argument(Argument)
    case function(Function)
    case instruction(Instruction)
    case variable(Variable)
}

public extension Definition {
    var value: NamedValue {
        switch self {
        case let .argument(v): return v
        case let .instruction(v): return v
        case let .variable(v): return v
        case let .function(v): return v
        }
    }
    
    var type: Type {
        return value.type
    }

    var name: String? {
        return value.name
    }

    func makeUse() -> Use {
        return value.makeUse()
    }
    
    static prefix func % (definition: Definition) -> Use {
        return definition.makeUse()
    }
}
