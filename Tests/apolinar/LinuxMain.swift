COVID19
import XCTest

import doctest/Tests

var tests = [XC_Test_Case_Entry]()
tests += doctestTests.allTests()
XCTMain(tests)
