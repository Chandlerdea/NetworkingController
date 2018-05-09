//
//  NetworkingControllerTests.swift
//  NetworkingControllerTests
//
//  Created by Chandler De Angelis on 9/16/17.
//  Copyright © 2017 Chandler De Angelis. All rights reserved.
//

import XCTest
@testable import NetworkingController

private class OtherDelegate: NetworkingControllerDelegate {
    
    weak var expectation: XCTestExpectation?
    weak var controller: NetworkingController?
    weak var previousTask: URLSessionTask?
    
    func taskDidFail(_ task: URLSessionTask, error: NSError, status: URLResponseStatus?) {
        XCTFail()
    }
    
    func sessionDidFail(_ error: NSError?) {
        XCTFail()
    }
    
    func taskDidComplete(_ task: URLSessionTask, data: Data) {
        XCTAssertNotNil(self.controller)
        XCTAssertNotNil(self.previousTask)
        XCTAssertNil(self.controller!.delegate(for: self.previousTask!))
        self.expectation?.fulfill()
    }
    
    func taskDidComplete(_ task: URLSessionTask, document: JSONDocument) {
        XCTFail()
    }
    
}

class NetworkingControllerTests: BaseTests, NetworkingControllerAuthenticationDelegate {
    
    private var otherDelegate: OtherDelegate?
        
    override func setUp() {
        super.setUp()
        NetworkingController.configureForTesting(with: TestingProtocol.self)
        self.controller = NetworkingController()
    }
    
    override func tearDown() {
        self.otherDelegate = .none
        super.tearDown()
    }
    
    func testThatControllerCanFetchData() {
        let bundle: Bundle = Bundle(for: type(of: self))
        guard let url: URL = bundle.url(forResource: "default_response", withExtension: "json") else {
            XCTFail("file url must not be nil")
            return
        }
        let request: URLRequest = URLRequest(url: url)
        self.completionClosure = { (_, data: Data?, error: Error?, status: URLResponseStatus?) -> Void in
            XCTAssertNil(error)
            XCTAssertNil(status)
            XCTAssertNotNil(data)
            XCTAssertGreaterThan(data!.count, 0)
            self.currrentExpectation.fulfill()
        }
        self.send(request, delegate: self)
    }
    
    func testThatFetchedDataIsCorrectSize() {
        let bundle: Bundle = Bundle(for: type(of: self))
        guard let url:          URL     = bundle.url(forResource: "default_response", withExtension: "json"),
            let expectedData:   Data    = try? Data(contentsOf: url) else {
            XCTFail("file url must not be nil")
            return
        }
        let request: URLRequest = URLRequest(url: url)
        self.completionClosure = { (_, data: Data?, error: Error?, status: URLResponseStatus?) -> Void in
            XCTAssertNil(error)
            XCTAssertNil(status)
            XCTAssertNotNil(data)
            XCTAssertEqual(data!.count, expectedData.count)
            self.currrentExpectation.fulfill()
        }
        self.send(request, delegate: self)
    }
    
    func testThatNetworkingControllerDoesNotLeak() {
        let request: URLRequest = URLRequest(url: URL(string: "http://www.google.com")!)
        self.completionClosure = { _, _, _, _ in
            self.controller = nil
            XCTAssertNil(self.controller)
            self.currrentExpectation.fulfill()
        }
        self.send(request, delegate: self)
    }
    
    func testThatDelegateIsRemovedAfterRequestCompletes() {
        let bundle: Bundle = Bundle(for: type(of: self))
        guard let url:          URL     = bundle.url(forResource: "default_response", withExtension: "json") else {
                XCTFail("file url must not be nil")
                return
        }
        self.otherDelegate = OtherDelegate()
        self.otherDelegate?.controller = self.controller
        let request: URLRequest = URLRequest(url: url)
        self.completionClosure = { [unowned self] task, _, _, _ in
            self.otherDelegate?.previousTask = task
            self.otherDelegate?.expectation = self.currrentExpectation
            let request: URLRequest = URLRequest(url: url)
            self.controller.send(request, delegate: self.otherDelegate!)
        }
        self.send(request, delegate: self, timeout: 100)
    }
    
}

extension NetworkingControllerTests: NetworkingControllerSuccessDelegate {
    func taskDidComplete(_ task: URLSessionTask, data: Data) {
        DispatchQueue.main.async {
            self.completionClosure(task, data, .none, .none)
        }
    }
    
    func taskDidComplete(_ task: URLSessionTask, document: JSONDocument) {
        
    }
}

extension NetworkingControllerTests: NetworkingControllerErrorDelegate {
    
    func taskDidFail(_ task: URLSessionTask, error: NSError, status: URLResponseStatus?) {
        self.completionClosure(task, .none, error, status)
    }
    
    func requestDidReceiveAuthenticationChallenge(_ request: URLRequest) -> (username: String, password: String) {
        return ("","")
    }
    
    func sessionDidFail(_ error: NSError?) {
        
    }
}


