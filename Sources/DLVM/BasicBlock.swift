//
//  BasicBlock.swift
//  DLVM
//
//  Created by Richard Wei on 12/18/16.
//
//

import Foundation

open class BasicBlock : IRCollection, IRObject {

    public typealias Element = Instruction

    open var name: String
    
    /// Take advantange of great data structures from Foundation
    let definitions = NSMutableOrderedSet()
    let instructions = NSMutableOrderedSet()
    
    open internal(set) weak var parent: Module?

    open var elements: [Instruction] {
        return instructions.array as! [Instruction]
    }

    public init(name: String) {
        self.name = name
    }

    public init(name: String, definitions: [VariableOperand], instructions: [Instruction]) {
        self.name = name
        self.definitions.addObjects(from: definitions)
        self.instructions.addObjects(from: instructions)
    }

}

// MARK: - IRCollection
extension BasicBlock {

    /// Append the definition instruction of the variable to the
    /// basic block, storing the variable into the basic block
    ///
    /// - Precondition: variable has a defining instruction
    open func appendDefinition(of variable: VariableOperand) {
        guard let instruction = variable.definition else {
            preconditionFailure("Variable has no definition")
        }
        definitions.add(variable)
        instructions.add(instruction)
    }

    /// Append the instruction to the basic block
    open func append(_ instruction: Instruction) {
        instructions.add(instruction)
        instruction.parent = self
    }

    /// Index of the instruction in the basic block
    open func index(of instruction: Instruction) -> Int? {
        return instructions.index(of: instruction)
    }

    /// Remove the instruction from the basic block
    ///
    /// - Precondition: instruction is in the basic block
    open func remove(_ instruction: Instruction) {
        instructions.remove(instruction)
        instruction.parent = nil
    }
    
}
