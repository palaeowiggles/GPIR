//
//  Variable.swift
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

/// Global variable
public class Variable : NamedValue, HashableByReference {
    public var name: String?
    /// The type of the underlying value of the variable
    public var valueType: Type
    
    unowned var parent: Module

    public init(name: String?, valueType: Type, parent: Module) {
        self.name = name
        self.valueType = valueType
        self.parent = parent
    }

    /// The pointer type wrapping the value type of the variable
    public var type: Type {
        return .pointer(valueType)
    }
}

extension Variable : Value {
    public func makeUse() -> Use {
        return .definition(.variable(self))
    }
}

public extension Variable {
    var printedName: String {
        if let name = name { return name }
        let selfIndex = parent.variables.index(of: self) ?? DLImpossibleResult()
        return selfIndex.description
    }
}
