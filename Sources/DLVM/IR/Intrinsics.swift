//
//  Intrinsics.swift
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

public final class IntrinsicRegistry {
    public static let global = IntrinsicRegistry(intrinsics: [
        MeanIntrinsic.self, SoftmaxIntrinsic.self,
        MinIntrinsic.self, MaxIntrinsic.self
    ])

    var registry: [String : Intrinsic.Type] = [:]

    public func register(_ intrinsic: Intrinsic.Type) {
        guard !registry.keys.contains(intrinsic.opcode) else {
            fatalError("Multiple intrinsics with opcode \(intrinsic.opcode)")
        }
        registry[intrinsic.opcode] = intrinsic
    }

    public func intrinsic(named opcode: String) -> Intrinsic.Type? {
        return registry[opcode]
    }

    init() {}

    init(intrinsics: [Intrinsic.Type]) {
        for intrinsic in intrinsics {
            register(intrinsic)
        }
    }
}

/// An intrinsic function
/// TODO:
/// - Add a way to register adjoint
/// - Add "ReductionIntrinsic"
public class Intrinsic {
    public class var opcode: String {
        fatalError("Must be implemented by subclasses.")
    }
    public class func resultType(for operands: [Use]) -> Type {
        fatalError("Must be implemented by subclasses.")
    }
}

extension Intrinsic {
    public static var description: String {
        return "builtin \"\(self.opcode)\""
    }
}

extension Intrinsic : Equatable {
    public static func == (lhs: Intrinsic, rhs: Intrinsic) -> Bool {
        return type(of: lhs) == type(of: rhs)
    }
}

public class UnaryIntrinsic : Intrinsic {}
public class BinaryIntrinsic : Intrinsic {}

public class NumericUnaryIntrinsic : UnaryIntrinsic {
    public override class func resultType(for operands: [Use]) -> Type {
        guard let first = operands.first, case let .tensor(s, dt) = first.type,
            dt.isNumeric else {
            return .invalid
        }
        return .tensor(s, dt)
    }
}

public class FloatingPointUnaryIntrinsic : NumericUnaryIntrinsic {
    public override class func resultType(for operands: [Use]) -> Type {
        guard let first = operands.first, case let .tensor(s, dt) = first.type,
            case .float = dt else {
            return .invalid
        }
        return .tensor(s, dt)
    }
}

public class NumericBinaryIntrinsic : BinaryIntrinsic {
    public override class func resultType(for operands: [Use]) -> Type {
        guard operands.count == 2,
            case let .tensor(s1, dt1) = operands[0].type,
            case let .tensor(s2, dt2) = operands[1].type,
            let bcShape = s1.broadcast(with: s2), dt1 == dt2, dt1.isNumeric else {
            return .invalid
        }
        return .tensor(bcShape, dt1)
    }
}

public class MeanIntrinsic : Intrinsic {
    /// WIP: `mean` is a reduction op and should accept reduction axes as an argument.
    public override class var opcode: String { return "mean" }
}

public class SoftmaxIntrinsic : FloatingPointUnaryIntrinsic {
    public override class var opcode: String { return "softmax" }
}

public class MinIntrinsic : NumericBinaryIntrinsic {
    public override class var opcode: String { return "min" }
}

public class MaxIntrinsic : NumericBinaryIntrinsic {
    public override class var opcode: String { return "max" }
}
