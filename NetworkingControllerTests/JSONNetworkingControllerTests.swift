//
//  JSONNetworkingControllerTests.swift
//  NetworkingControllerTests
//
//  Created by Chandler De Angelis on 9/18/17.
//  Copyright © 2017 Chandler De Angelis. All rights reserved.
//

import XCTest
@testable import NetworkingController

class JSONNetworkingControllerTests: BaseTests {
    
    override func setUp() {
        super.setUp()
        self.controller = JSONNetworkingController(sessionConfiguration: .ephemeral)
        self.controller.successDelegate = self
        self.controller.errorDelegate = self
        self.controller.urlProtocols = [TestingProtocol.self]
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testThatErrorIsThrownForWrongUrl() {
        let wrongUrl: URL = URL(fileURLWithPath: "wrong_url.json")
        let request: URLRequest = URLRequest(url: wrongUrl)
        self.completionClosure = { (data: Data?, error: Error?, status: URLResponseStatus?) -> Void in
            XCTAssertNil(data)
            XCTAssertNotNil(error)
            XCTAssertNotNil(status)
            XCTAssertEqual(status!, URLResponseStatus.BadRequest)
            self.currrentExpectation.fulfill()
        }
        self.send(request)
    }
    
}

extension JSONNetworkingControllerTests: NetworkingControllerSuccessDelegate {
    
    func requestDidComplete(_ request: URLRequest, data: Data) {
        self.completionClosure(data, .none, .none)
    }
}

extension JSONNetworkingControllerTests: NetworkingControllerErrorDelegate {
    
    func requestDidFail(_ request: URLRequest, error: NSError, status: URLResponseStatus?) {
        self.completionClosure(.none, error, status)
    }
    
    func sessionDidFail(_ error: NSError?) {
        
    }
}