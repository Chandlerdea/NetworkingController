//
//  XCTest+Helpers.swift
//  rip-harambe-workout-trackerTests
//
//  Created by Chandler De Angelis on 8/18/17.
//  Copyright © 2017 Chandler De Angelis. All rights reserved.
//

import Foundation
import XCTest

extension XCTestCase {
    
    func defaultExpectation() -> XCTestExpectation {
        return self.expectation(description: "default expectation")
    }
    
    func defaultWait() {
        self.waitForExpectations(timeout: 10, handler: { (error: Error?) in
            if let unwrappedError: Error = error {
                XCTFail("\(unwrappedError)")
            }
        })
    }
}


