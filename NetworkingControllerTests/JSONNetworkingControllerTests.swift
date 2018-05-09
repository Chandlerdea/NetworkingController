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
    
    private var jsonApiCompletion: ((JSONDocument?, Error?, URLResponseStatus?) -> Void)!
    
    var enteredUsername: String?
    var enteredPassword: String?
    var canProceedWithoutAuthentication: Bool = false
    
    private var okJSONAPIRequest: URLRequest {
        let bundle: Bundle = Bundle(for: type(of: self))
        let url: URL = bundle.url(forResource: "jsonapi_response", withExtension: "json")!
        return URLRequest(url: url)
    }
    
    override func setUp() {
        super.setUp()
        NetworkingController.configureForTesting(with: TestingProtocol.self)
        self.controller = JSONNetworkingController()
    }
    
    override func tearDown() {
        self.enteredUsername = .none
        self.enteredPassword = .none
        self.canProceedWithoutAuthentication = false
        super.tearDown()
    }
    
    func testThatResponseIsOK() {
        let okURL: URL = URL(string: "http://www.test.com")!
        let request: URLRequest = URLRequest(url: okURL)
        self.completionClosure = { (_, data: Data?, error: Error?, status: URLResponseStatus?) -> Void in
            XCTAssertNotNil(data)
            XCTAssertNil(error)
            XCTAssertEqual(status, .OK)
            self.currrentExpectation.fulfill()
        }
        self.send(request, delegate: self)
    }
    
    func testThatErrorIsThrownForWrongUrl() {
        let wrongUrl: URL = URL(string: "http://www.test.com/wrong_url")!
        let request: URLRequest = URLRequest(url: wrongUrl)
        self.completionClosure = { (_, data: Data?, error: Error?, status: URLResponseStatus?) -> Void in
            XCTAssertNil(data)
            XCTAssertNotNil(error)
            XCTAssertNotNil(status)
            XCTAssertEqual(status!, .BadRequest)
            self.currrentExpectation.fulfill()
        }
        self.send(request, delegate: self)
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
        self.completionClosure = { (_, data: Data?, error: Error?, status: URLResponseStatus?) -> Void in
            XCTAssertNotNil(data)
            XCTAssertNil(error)
            XCTAssertEqual(status, .OK)
            self.currrentExpectation.fulfill()
        }
        self.send(request, delegate: self)
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
        self.completionClosure = { (_, data: Data?, error: Error?, status: URLResponseStatus?) -> Void in
            XCTAssertNil(data)
            XCTAssertNotNil(error)
            XCTAssertEqual(status, .Unauthorized)
            self.currrentExpectation.fulfill()
        }
        self.send(request, delegate: self)
    }
    
    func testThatResponseIsOKWhenAuthenticationIsNotRequired() {
        let bundle: Bundle = Bundle(for: type(of: self))
        guard let authUrl: URL = bundle.url(forResource: "challenge_no_credentials_needed_response", withExtension: "json") else {
            XCTFail("file url must not be nil")
            return
        }
        let request: URLRequest = URLRequest(url: authUrl)
        self.completionClosure = { (_, data: Data?, error: Error?, status: URLResponseStatus?) -> Void in
            XCTAssertNotNil(data)
            XCTAssertNil(error)
            XCTAssertEqual(status, .OK)
            self.currrentExpectation.fulfill()
        }
        self.send(request, delegate: self)
    }
    
    // MARK: JSON API
    
    func testThatJSONAPIDocumentIsNotNil() {
        self.jsonApiCompletion = { (document: JSONDocument?, error: Error?, status: URLResponseStatus?) -> Void in
            XCTAssertEqual(status, .OK, "status is not OK")
            XCTAssertNil(error, "error is not nil")
            XCTAssertNotNil(document, "document is nil")
            self.currrentExpectation.fulfill()
        }
        self.send(self.okJSONAPIRequest, delegate: self)
    }
}

extension JSONNetworkingControllerTests: NetworkingControllerSuccessDelegate {
    
    func taskDidComplete(_ task: URLSessionTask, data: Data) {
        self.completionClosure?(task, data, .none, .OK)
    }
    
    func taskDidComplete(_ task: URLSessionTask, document: JSONDocument) {
        self.jsonApiCompletion?(document, .none, .OK)
    }
}

extension JSONNetworkingControllerTests: NetworkingControllerAuthenticationDelegate {
    
    func requestDidReceiveAuthenticationChallenge(_ request: URLRequest) -> (username: String, password: String)? {
        guard let username: String = self.enteredUsername, let password: String = self.enteredPassword, request.url?.pathComponents.last == "username_password_response.json" else {
            return .none
        }
        return (username, password)
    }
    
    func shouldProceedWithAuthenticationChallendWithoutCredentials(_ request: URLRequest) -> Bool {
        return self.canProceedWithoutAuthentication
    }
}

extension JSONNetworkingControllerTests: NetworkingControllerErrorDelegate {
    func taskDidFail(_ task: URLSessionTask, error: NSError, status: URLResponseStatus?) {
        self.completionClosure(task, .none, error, status)
    }
    
    func sessionDidFail(_ error: NSError?) {
        
    }
}
