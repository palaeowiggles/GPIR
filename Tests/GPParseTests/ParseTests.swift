//
//  ParseTests.swift
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

import XCTest
@testable import GPParse

class ParseTests : XCTestCase {
    func testType() throws {
        let types = [
            "bool",
            "*bool",
            "(bool, (bool, bool))"
        ]
        for type in types {
            do {
                let parser = try Parser(text: type)
                _ = try parser.parseType()
            } catch {
                XCTFail(String(describing: error) + " when parsing \"\(type)\"")
            }
        }
    }

    func testUse() throws {
        let uses = [
            "true : bool",
            """
            (false : bool, (true : bool, false : bool): (bool, bool)) : (bool, (bool, bool))
            """,
            "false :///comments\n\n bool>",
            "{ #hello = false : bool, #value = true: bool } : bool"
        ]
        for type in uses {
            do {
                let parser = try Parser(text: type)
                _ = try parser.parseUse(in: nil)
            } catch {
                XCTFail(String(describing: error) + " when parsing \"\(type)\"")
            }
        }
    }

    func testInstructionKind() throws {
        let uses = [
            "literal (true: bool, false: bool): (bool, bool)",
            "and true: bool, false: bool",
            "elementPointer true: *bool at #name1, #name2, 3, 4",
        ]
        for type in uses {
            do {
                let parser = try Parser(text: type)
                _ = try parser.parseInstructionKind(in: nil)
            } catch {
                XCTFail(String(describing: error) + " when parsing \"\(type)\"")
            }
        }
    }

    static var allTests: [(String, (ParseTests) -> () throws -> Void)] {
        return [
            ("testType", testType),
            ("testUse", testUse),
            ("testInstructionKind", testInstructionKind)
        ]
    }
}
