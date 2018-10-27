//
//  Passes.swift
//  GPCommandLineTools
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

import GPIR
import protocol Utility.StringEnumArgument
import enum Utility.ShellCompletion

public enum TransformPass: String, CaseIterable {
    case algebraSimplification = "AlgebraSimplification"
    case cfgCanonicalization = "CFGCanonicalization"
    case cfgSimplification = "CFGSimpliciation"
    case commonSubexpressionElimination = "CommonSubexpressionElimination"
    case deadCodeElimination = "DeadCodeElimination"
    case literalBroadcastingPromotion = "LiteralBroadcastingPromotion"
    case stackPromotion = "StackPromotion"
    case valuePromotion = "ValuePromotion"
}

public extension TransformPass {
    var abbreviation: String {
        switch self {
        case .algebraSimplification: return "AS"
        case .cfgCanonicalization: return "CFGCan"
        case .cfgSimplification: return "CFGSimp"
        case .commonSubexpressionElimination: return "CSE"
        case .deadCodeElimination: return "DCE"
        case .literalBroadcastingPromotion: return "LBP"
        case .stackPromotion: return "SP"
        case .valuePromotion: return "VP"
        }
    }

    var description: String {
        switch self {
        case .algebraSimplification: return "algebra simplification"
        case .cfgCanonicalization: return "CFG canonicalization"
        case .cfgSimplification: return "CFG simplification"
        case .commonSubexpressionElimination:
            return "common subexpression elimination"
        case .deadCodeElimination: return "dead code elimination"
        case .literalBroadcastingPromotion:
            return "literal broadcasting promotion"
        case .stackPromotion: return "stack promotion"
        case .valuePromotion: return "value promotion"
        }
    }

    // NOTE: Can be shortened with enum iteration
    init?(rawValue: String) {
        typealias T = TransformPass
        for transform in TransformPass.allCases {
            if rawValue == transform.abbreviation ||
                rawValue == transform.rawValue {
                self = transform
                return
            }
        }
        return nil
    }
}

extension TransformPass : StringEnumArgument {
    public static var completion: ShellCompletion {
        return .values(allCases.map { ($0.abbreviation, $0.description) })
    }
}

public func runPass(_ pass: TransformPass, on module: Module,
                    bypassingVerification noVerify: Bool = false) throws {
    var changed: Bool
    switch pass {
    case .algebraSimplification:
        changed = module.mapTransform(AlgebraSimplification.self,
                                      bypassingVerification: noVerify)
    case .cfgCanonicalization:
        changed = module.mapTransform(CFGCanonicalization.self,
                                      bypassingVerification: noVerify)
    case .cfgSimplification:
        changed = module.mapTransform(CFGSimplification.self,
                                      bypassingVerification: noVerify)
    case .commonSubexpressionElimination:
        changed = module.mapTransform(CommonSubexpressionElimination.self,
                                      bypassingVerification: noVerify)
    case .deadCodeElimination:
        changed = module.mapTransform(DeadCodeElimination.self,
                                      bypassingVerification: noVerify)
    case .literalBroadcastingPromotion:
        changed = module.mapTransform(LiteralBroadcastingPromotion.self,
                                      bypassingVerification: noVerify)
    case .stackPromotion:
        changed = module.mapTransform(StackPromotion.self,
                                      bypassingVerification: noVerify)
    case .valuePromotion:
        changed = module.mapTransform(ValuePromotion.self,
                                      bypassingVerification: noVerify)
    }
    print("\(pass.abbreviation):", changed ? "changed" : "unchanged")
}
