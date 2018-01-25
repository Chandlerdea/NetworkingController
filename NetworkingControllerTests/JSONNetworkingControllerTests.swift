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
    
    var enteredUsername: String?
    var enteredPassword: String?
    
    override func setUp() {
        super.setUp()
        self.controller = JSONNetworkingController(sessionConfiguration: .ephemeral)
        self.controller.successDelegate = self
        self.controller.errorDelegate = self
        self.controller.urlProtocols = [TestingProtocol.self]
    }
    
    override func tearDown() {
        self.enteredUsername = .none
        self.enteredPassword = .none
        super.tearDown()
    }
    
    func testThatResponseIsOK() {
        let okURL: URL = URL(string: "http://www.test.com")!
        let request: URLRequest = URLRequest(url: okURL)
        self.completionClosure = { (data: Data?, error: Error?, status: URLResponseStatus?) -> Void in
            XCTAssertNotNil(data)
            XCTAssertNil(error)
            XCTAssertEqual(status, .OK)
            self.currrentExpectation.fulfill()
        }
        self.send(request)
    }
    
    func testThatErrorIsThrownForWrongUrl() {
        let wrongUrl: URL = URL(string: "http://www.test.com/wrong_url")!
        let request: URLRequest = URLRequest(url: wrongUrl)
        self.completionClosure = { (data: Data?, error: Error?, status: URLResponseStatus?) -> Void in
            XCTAssertNil(data)
            XCTAssertNotNil(error)
            XCTAssertNotNil(status)
            XCTAssertEqual(status!, .BadRequest)
            self.currrentExpectation.fulfill()
        }
        self.send(request)
    }
    
    func testThatResponseIsOKWhenCorrectUsernamePasswordIsProvided() {
        let bundle: Bundle = Bundle(for: type(of: self))
        guard let authUrl: URL = bundle.url(forResource: "username_password_response", withExtension: "json") else {
            XCTFail("file url must not be nil")
            return
        }
        self.enteredUsername = TestingProtocol.correctUsername
        self.enteredPassword = TestingProtocol.correctPassword
        let request: URLRequest = URLRequest(url: authUrl)
        self.completionClosure = { (data: Data?, error: Error?, status: URLResponseStatus?) -> Void in
            XCTAssertNotNil(data)
            XCTAssertNil(error)
            XCTAssertEqual(status, .OK)
            self.currrentExpectation.fulfill()
        }
        self.send(request)
    }
    

    func testThatResponseIsUnauthorizedWhenIncorrectUsernamePasswordIsProvided() {
        let bundle: Bundle = Bundle(for: type(of: self))
        guard let authUrl: URL = bundle.url(forResource: "username_password_response", withExtension: "json") else {
            XCTFail("file url must not be nil")
            return
        }
        self.enteredUsername = "wrong"
        self.enteredPassword = "wrong"
        let request: URLRequest = URLRequest(url: authUrl)
        self.completionClosure = { (data: Data?, error: Error?, status: URLResponseStatus?) -> Void in
            XCTAssertNil(data)
            XCTAssertNotNil(error)
            XCTAssertEqual(status, .Unauthorized)
            self.currrentExpectation.fulfill()
        }
        self.send(request)
    }
}

extension JSONNetworkingControllerTests: NetworkingControllerSuccessDelegate {
    
    func requestDidComplete(_ request: URLRequest, data: Data) {
        self.completionClosure(data, .none, .OK)
    }
}

extension JSONNetworkingControllerTests: NetworkingControllerErrorDelegate {
    
    func requestDidReceiveAuthenticationChallenge(_ request: URLRequest) -> (username: String, password: String)? {
        guard let username: String = self.enteredUsername, let password: String = self.enteredPassword, request.url?.pathComponents.last == "username_password_response.json" else {
            return .none
        }
        return (username, password)
    }
    
    func requestDidFail(_ request: URLRequest, error: NSError, status: URLResponseStatus?) {
        self.completionClosure(.none, error, status)
    }
    
    func sessionDidFail(_ error: NSError?) {
        
    }
}
