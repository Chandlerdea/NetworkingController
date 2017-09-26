//
//  NetworkingControllerTests.swift
//  NetworkingControllerTests
//
//  Created by Chandler De Angelis on 9/16/17.
//  Copyright © 2017 Chandler De Angelis. All rights reserved.
//

import XCTest
@testable import NetworkingController

class NetworkingControllerTests: BaseTests {
    
    override func setUp() {
        super.setUp()
        self.controller = NetworkingController(sessionConfiguration: .ephemeral)
        self.controller.successDelegate = self
        self.controller.errorDelegate = self
        self.controller.urlProtocols = [TestingProtocol.self]
    }
    
    override func tearDown() {
        
        super.tearDown()
    }
    
    func testThatControllerCanFetchData() {
        let bundle: Bundle = Bundle(for: type(of: self))
        guard let url: URL = bundle.url(forResource: "default_response", withExtension: "json") else {
            XCTFail("file url must not be nil")
            return
        }
        let request: URLRequest = URLRequest(url: url)
        self.completionClosure = { (data: Data?, error: Error?, status: URLResponseStatus?) -> Void in
            XCTAssertNil(error)
            XCTAssertNil(status)
            XCTAssertNotNil(data)
            XCTAssertGreaterThan(data!.count, 0)
            self.currrentExpectation.fulfill()
        }
        self.send(request)
    }
    
    func testThatFetchedDataIsCorrectSize() {
        let bundle: Bundle = Bundle(for: type(of: self))
        guard let url:          URL     = bundle.url(forResource: "default_response", withExtension: "json"),
            let expectedData:   Data    = try? Data(contentsOf: url) else {
            XCTFail("file url must not be nil")
            return
        }
        let request: URLRequest = URLRequest(url: url)
        self.completionClosure = { (data: Data?, error: Error?, status: URLResponseStatus?) -> Void in
            XCTAssertNil(error)
            XCTAssertNil(status)
            XCTAssertNotNil(data)
            XCTAssertEqual(data!.count, expectedData.count)
            self.currrentExpectation.fulfill()
        }
        self.send(request)
    }
    
    
}

extension NetworkingControllerTests: NetworkingControllerSuccessDelegate {
    
    func requestDidComplete(_ request: URLRequest, data: Data) {
        self.completionClosure(data, .none, .none)
    }
}

extension NetworkingControllerTests: NetworkingControllerErrorDelegate {
    
    func requestDidReceiveAuthenticationChallenge(_ request: URLRequest) -> (username: String, password: String) {
        return ("","")
    }
    
    func requestDidFail(_ request: URLRequest, error: NSError, status: URLResponseStatus?) {
        self.completionClosure(.none, error, status)
    }
    
    func sessionDidFail(_ error: NSError?) {
        
    }
}


