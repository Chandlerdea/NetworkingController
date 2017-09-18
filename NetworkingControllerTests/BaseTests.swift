//
//  BaseTests.swift
//  NetworkingControllerTests
//
//  Created by Chandler De Angelis on 9/18/17.
//  Copyright © 2017 Chandler De Angelis. All rights reserved.
//

import XCTest
@testable import NetworkingController

class BaseTests: XCTestCase {
    
    var completionClosure: ((Data?, Error?, URLResponseStatus?) -> ())!
    var currrentExpectation: XCTestExpectation!
    var controller: NetworkingController!
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func send(_ request: URLRequest) {
        self.currrentExpectation = self.defaultExpectation()
        self.controller.perform(request: request)
        self.defaultWait()
    }
    
}
