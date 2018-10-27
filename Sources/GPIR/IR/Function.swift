//
//  Function.swift
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

public final class Function : IRCollection, IRUnit, NamedValue {
    public enum Attribute {
        /// To be inlined
        case inline
    }

    public enum DeclarationKind {
        /// Externally defined
        case external
    }

    public typealias Base = OrderedSet<BasicBlock>
    public typealias Element = BasicBlock

    public var name: String?
    public var argumentTypes: [Type]
    public var returnType: Type
    public var attributes: Set<Attribute> = []
    public var declarationKind: DeclarationKind?
    public var parent: Module

    public var elements: OrderedSet<BasicBlock> = []
    public internal(set) var passManager: PassManager<Function> = PassManager()

    public init(name: String?, argumentTypes: [Type],
                returnType: Type, attributes: Set<Attribute> = [],
                declarationKind: DeclarationKind? = nil, parent: Module) {
        self.name = name
        self.argumentTypes = argumentTypes
        self.returnType = returnType
        self.attributes = attributes
        self.declarationKind = declarationKind
        self.parent = parent
    }

    public var canApplyTransforms: Bool {
        return !isDeclaration
    }
}

/// - Note: This is a workaround for a type checker bug in Swift 4
public extension Function {
    func append(_ newElement: Element) {
        elements.append(newElement)
        newElement.parent = self
        invalidatePassResults()
    }

    func insert(_ newElement: Element, at index: Base.Index) {
        elements.insert(newElement, at: index)
        newElement.parent = self
        invalidatePassResults()
    }

    func insert(_ newElement: Element, after other: Element) {
        elements.insert(newElement, after: other)
        newElement.parent = self
        invalidatePassResults()
    }

    func insert(_ newElement: Element, before other: Element) {
        elements.insert(newElement, before: other)
        newElement.parent = self
        invalidatePassResults()
    }
}

extension Function : Value {
    public var type: Type {
        return .function(argumentTypes, returnType)
    }

    public func makeUse() -> Use {
        return .definition(.function(self))
    }
}

public extension Function {
    func acceptsArguments<C : Collection>(_ types: C) -> Bool
        where C.Element == Type
    {
        guard types.count == argumentTypes.count else { return false }
        return zip(types, argumentTypes).forAll { actual, formal in
            actual.conforms(to: formal)
        }
    }

    var isDeclaration: Bool {
        return declarationKind != nil
    }

    var isDefinition: Bool {
        return declarationKind == nil
    }

    var instructions: LazyCollection<FlattenCollection<Function>> {
        return lazy.joined()
    }
}

public extension Function {
    /// Replace all occurrences of an instruction with another use
    func replaceAllUses(of oldInstruction: Instruction, with newUse: Use) {
        /// If `instruction` exists in its parent BB in this function,
        /// we only search the area after `instruction`'s definition
        if oldInstruction.existsInParent, oldInstruction.parent.parent == self {
            let bbIndex = oldInstruction.parent.indexInParent
            let instIndex = oldInstruction.indexInParent
            for bb in suffix(from: bbIndex) {
                for inst in bb where bb != oldInstruction.parent ||
                    inst.indexInParent >= instIndex {
                    inst.substitute(newUse, for: %oldInstruction)
                }
            }
        }
        /// Otherwise, we search every use for `instruction`
        else {
            for inst in instructions {
                inst.substitute(newUse, for: %oldInstruction)
            }
        }
    }

    /// Replace all occurrences of a use with another use
    func replaceAllUses(of oldUse: Use, with newUse: Use) {
        switch oldUse {
        case let .definition(.instruction(inst)):
            replaceAllUses(of: inst, with: newUse)
        default:
            for inst in instructions {
                inst.substitute(newUse, for: oldUse)
            }
        }
    }
}

public extension Function {
    var printedName: String {
        if let name = name { return name }
        let selfIndex = parent.variables.count + indexInParent
        return selfIndex.description
    }
}
