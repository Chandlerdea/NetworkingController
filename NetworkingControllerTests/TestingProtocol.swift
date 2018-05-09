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
    
    static let correctUsername: String = "test"
    static let correctPassword: String = "123"
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    private func sendBadURLResponse() {
        let response: URLResponse = HTTPURLResponse(url: self.request.url!, statusCode: URLResponseStatus.BadRequest.rawValue, httpVersion: "1.1", headerFields: .none)!
        self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        self.client?.urlProtocolDidFinishLoading(self)
    }
    
    private func sendUnauthorizedResponse() {
        let response: URLResponse = HTTPURLResponse(url: self.request.url!, statusCode: URLResponseStatus.Unauthorized.rawValue, httpVersion: "1.1", headerFields: .none)!
        self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        self.client?.urlProtocolDidFinishLoading(self)
    }
    
    private func sendOkResponse(for url: URL) {
        let jsonData: Data
        switch url.pathComponents.last {
        case "default_response.json"?,
             "username_password_response.json"?,
             "jsonapi_response.json"?:
            jsonData = try! Data(contentsOf: url)
        default:
            jsonData = Data()
        }
        let response: HTTPURLResponse = HTTPURLResponse(url: self.request.url!, statusCode: URLResponseStatus.OK.rawValue, httpVersion: "1.1", headerFields: .none)!
        self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        self.client?.urlProtocol(self, didLoad: jsonData)
        self.client?.urlProtocolDidFinishLoading(self)
    }
    
    override func startLoading() {
        guard let url: URL = self.request.url else {
            self.sendBadURLResponse()
            return
        }
        switch url.pathComponents.last {
        case "wrong_url"?:
            self.sendBadURLResponse()
        case "username_password_response.json"? where FileManager.default.fileExists(atPath: url.path),
             "chanllenge_no_credentials_needed"? where FileManager.default.fileExists(atPath: url.path):
            let protectionSpece: URLProtectionSpace = URLProtectionSpace(host: "", port: 443, protocol: .none, realm: .none, authenticationMethod: NSURLAuthenticationMethodHTTPBasic)
            let challenge: URLAuthenticationChallenge = URLAuthenticationChallenge(protectionSpace: protectionSpece, proposedCredential: .none, previousFailureCount: 0, failureResponse: .none, error: .none, sender: self as URLAuthenticationChallengeSender)
            self.client?.urlProtocol(self, didReceive: challenge)
        default:
            self.sendOkResponse(for: url)
        }
    }
    
    override func stopLoading() {
        
    }
    
}

extension TestingProtocol: URLAuthenticationChallengeSender {
    
    func use(_ credential: URLCredential, for challenge: URLAuthenticationChallenge) {
        let isUsernamePasswordCorrect: Bool = credential.user == TestingProtocol.correctUsername && credential.password == TestingProtocol.correctPassword
        guard let fileUrl: URL = self.request.url, FileManager.default.fileExists(atPath: fileUrl.path), isUsernamePasswordCorrect else {
            self.sendUnauthorizedResponse()
            return
        }
        self.sendOkResponse(for: fileUrl)
    }
    
    func performDefaultHandling(for challenge: URLAuthenticationChallenge) {
        self.sendOkResponse(for: self.request.url!)
    }
    
    func continueWithoutCredential(for challenge: URLAuthenticationChallenge) {
        
    }
    
    func cancel(_ challenge: URLAuthenticationChallenge) {
        
    }
    
}


