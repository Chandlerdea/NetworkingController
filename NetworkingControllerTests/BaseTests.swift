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
    
    var completionClosure: ((URLSessionTask, Data?, Error?, URLResponseStatus?) -> ())!
    var currrentExpectation: XCTestExpectation!
    var controller: NetworkingController!
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func send(_ request: URLRequest, delegate: NetworkingControllerDelegate, timeout: TimeInterval = 2) {
        self.currrentExpectation = self.defaultExpectation()
        self.controller.send(request, delegate: delegate)
        self.defaultWait(timeout: timeout)
    }
    
}
