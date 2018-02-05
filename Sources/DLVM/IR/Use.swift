//
//  Use.swift
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

public indirect enum Use : Equatable {
    case literal(Type, Literal)
    case definition(Definition)
}

public extension Use {
    var type: Type {
        switch self {
        case let .literal(t, _):
            return t
        case let .definition(x):
            return x.type
        }
    }

    var tensorType: TensorType? {
        return type.tensorType
    }

    var value: Value {
        switch self {
        case let .literal(ty, lit): return LiteralValue(type: ty, literal: lit)
        case let .definition(def): return def.value
        }
    }

    var definition: Definition? {
        guard case let .definition(def) = self else { return nil }
        return def
    }

    var name: String? {
        switch self {
        case .literal: return nil
        case let .definition(def): return def.name
        }
    }

    var instruction: Instruction? {
        guard case let .definition(.instruction(inst)) = self else { return nil }
        return inst
    }

    var variable: Variable? {
        guard case let .definition(.variable(variable)) = self else { return nil }
        return variable
    }

    var literal: Literal? {
        guard case let .literal(_, lit) = self else {
            return nil
        }
        return lit
    }
}

infix operator ~

public func ~ (lhs: Literal, rhs: Type) -> Use {
    return .literal(rhs, lhs)
}
