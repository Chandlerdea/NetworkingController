//
//  NetworkingController.swift
//  SpinlisterKit
//
//  Created by Chandler De Angelis on 2/11/16.
//  Copyright © 2016 Spinlister LLC. All rights reserved.
//

import Foundation

open class NetworkingController: NSObject {
    
    open var urlProtocols: [AnyClass]? {
        get {
            return self.sessionConfiguration.protocolClasses
        }
        set {
            self.sessionConfiguration.protocolClasses = newValue
        }
    }
    
    private let sessionConfiguration: URLSessionConfiguration

    private lazy var session: URLSession = {
        let queue: OperationQueue = OperationQueue()
        queue.maxConcurrentOperationCount = 5
        return URLSession(
            configuration: self.sessionConfiguration,
            delegate: self,
            delegateQueue: queue
        )
    }()
    
    private var _requestForValidation: URLRequest?
    
    var requestForValidation: URLRequest? {
        return self._requestForValidation
    }

    private var requests: [Int: URLRequest] = [:]
    private var responseData: [Int: Data] = [:]

    private let responseDataAccessQueue: DispatchQueue = DispatchQueue(label: "com.spinlister.networkingcontroller")
    
    private let serverTrustDelegate: ServerTrustDelegate = ServerTrustDelegate()
    private let basicAuthDelegate: HTTPBasicAuthDelegate = HTTPBasicAuthDelegate()

    open var successDelegate: NetworkingControllerSuccessDelegate?
    open var errorDelegate: NetworkingControllerErrorDelegate? {
        didSet {
            self.basicAuthDelegate.errorDelegate = self.errorDelegate
        }
    }
    
    init(sessionConfiguration: URLSessionConfiguration) {
        self.sessionConfiguration = sessionConfiguration
        super.init()
    }
    
    override init() {
        self.sessionConfiguration = .default
        super.init()
    }
    
    deinit {
        self.session.invalidateAndCancel()
    }

    // Returns the task ID
    @discardableResult public func perform(request: URLRequest) -> Int {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        let dataTask: URLSessionDataTask = self.session.dataTask(with: request)
        self.requests[dataTask.taskIdentifier] = request
        
        self.readResponseData({ (data: inout [Int: Data]) in
            data[dataTask.taskIdentifier] = Data()
        }) {
            dataTask.resume()
        }
        
        return dataTask.taskIdentifier
    }

    private func readResponseData(_ closure: @escaping (_ mutableData: inout [Int: Data]) -> Void, completion: (() -> Void)? = nil) {
        self.responseDataAccessQueue.async {
            closure(&self.responseData)
            completion?()
        }
    }

    private func throwReachabilityError(withRequest request: URLRequest) {
        DispatchQueue.main.async {
            let error: NSError = NSError.noInternetConnectionError
            self.errorDelegate?.requestDidFail(request, error: error, status: .none)
        }
    }

}

public protocol NetworkingControllerErrorDelegate {
    func requestDidReceiveAuthenticationChallenge(_ request: URLRequest) -> (username: String, password: String)?
    func requestDidFail(_ request: URLRequest, error: NSError, status: URLResponseStatus?)
    func sessionDidFail(_ error: NSError?)
}

extension NetworkingControllerErrorDelegate {
    func requestDidReceiveAuthenticationChallenge(_ request: URLRequest) -> (username: String, password: String)? {
        return .none
    }
}

public protocol NetworkingControllerSuccessDelegate {
    func requestDidComplete(_ request: URLRequest, data: Data)
}

extension NetworkingController: URLSessionDataDelegate {
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        self.readResponseData({ (allData: inout [Int: Data]) in
            
            guard let existingData: Data = allData[dataTask.taskIdentifier] else {
                allData[dataTask.taskIdentifier] = Data()
                return
            }
            
            var newData: Data = existingData
            newData.append(data)
            allData[dataTask.taskIdentifier] = newData
        })
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        guard let request: URLRequest = self.requests[task.taskIdentifier] else {
            assertionFailure("request must not be nil")
            return
        }
        self.readResponseData({ (allData: inout [Int: Data]) in
            guard let existingData: Data        = allData[task.taskIdentifier],
                let response:       URLResponse = task.response else {
                    assertionFailure("reponse and data for request must not be nil")
                    return
            }
            do {
                self._requestForValidation = request
                if let validation: APIURLResponseValidationType = self as? APIURLResponseValidationType {
                    try validation.validateResponse(response)
                }
                DispatchQueue.main.async {
                    self.successDelegate?.requestDidComplete(request, data: existingData)
                }
            } catch {
                let status: URLResponseStatus? = (task.response as? HTTPURLResponse).flatMap({ URLResponseStatus(rawValue: $0.statusCode) })
                var errorUserInto: [String: Any] = [:]
                if let json: JSONDictionary? = try? JSONSerialization.jsonObject(with: existingData, options: []) as? JSONDictionary {
                    if let nestedErrorString: String = json?["error"].flatMap(JSONArrayObject)?.first as? String {
                        errorUserInto[NSLocalizedDescriptionKey] = nestedErrorString
                    } else if let errorString: String = json?["error"] as? String {
                        errorUserInto[NSLocalizedDescriptionKey] = errorString
                    } else {
                        errorUserInto[NSLocalizedDescriptionKey] = NSLocalizedString("An unknown error occurred", comment: "")
                    }
                } else {
                    errorUserInto[NSLocalizedDescriptionKey] = NSLocalizedString("An unknown error occurred", comment: "")
                }
                let URLError = NSError(domain: "com.spinlister.NetworkingController", code: 0, userInfo: errorUserInto)
                DispatchQueue.main.async {
                    self.errorDelegate?.requestDidFail(request, error: URLError, status: status)
                }
                return
            }
        })
    }
}

extension NetworkingController: URLSessionTaskDelegate {
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        guard challenge.previousFailureCount == 0 else {
            self.cancel(challenge, completionHandler: completionHandler)
            return
        }
        
        let authenticationMethod: String = challenge.protectionSpace.authenticationMethod
        
        switch authenticationMethod {
        case NSURLAuthenticationMethodHTTPBasic,
             NSURLAuthenticationMethodHTTPDigest:
            // create URLCredential with username/password, ask user for it
            self.basicAuthDelegate.urlSession(session, task: task, didReceive: challenge, completionHandler: completionHandler)
            
        case NSURLAuthenticationMethodClientCertificate:
            // client provides cert for server to verify
            // but the client should also verify the cert from the server, if the server sends it
            fallthrough
            
        case NSURLAuthenticationMethodServerTrust:
            // server provides cert for client to verify
            self.serverTrustDelegate.urlSession(session, task: task, didReceive: challenge, completionHandler: completionHandler)
            
        default:
            self.performDefaultHandling(challenge, completionHandler: completionHandler)
        }
    }

}

