import XCTest
@testable import GPIRTests
@testable import GPParseTests

XCTMain([
     // GPIRTests
     testCase(ADTTests.allTests),
     testCase(AnalysisTests.allTests),
     testCase(GraphTests.allTests),
     testCase(IRTests.allTests),
     testCase(TransformTests.allTests),
     // GPParseTests
     testCase(LexTests.allTests),
     testCase(ParseTests.allTests)
])
