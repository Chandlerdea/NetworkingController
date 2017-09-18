//
//  TestingProtocol.swift
//  NetworkingControllerTests
//
//  Created by Chandler De Angelis on 9/16/17.
//  Copyright © 2017 Chandler De Angelis. All rights reserved.
//

import Foundation
@testable import NetworkingController

final class TestingProtocol: URLProtocol {
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let fileUrl: URL = self.request.url, FileManager.default.fileExists(atPath: fileUrl.path) else {
            let response: URLResponse = HTTPURLResponse(url: self.request.url!, statusCode: URLResponseStatus.BadRequest.rawValue, httpVersion: "1.1", headerFields: .none)!
            self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            self.client?.urlProtocolDidFinishLoading(self)
            return
        }
        let jsonData: Data = try! Data(contentsOf: fileUrl)
        let response: HTTPURLResponse = HTTPURLResponse(url: self.request.url!, statusCode: 200, httpVersion: "1.1", headerFields: .none)!
        self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        self.client?.urlProtocol(self, didLoad: jsonData)
        self.client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {
        
    }
    
}

