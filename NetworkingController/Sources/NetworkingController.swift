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
    
    private lazy var certificates: [Data] = {
        let urls: [URL] = Bundle.main.urls(forResourcesWithExtension: "cer", subdirectory: .none) ?? []
        return urls.flatMap({ try? Data(contentsOf: $0) })
    }()

    open var errorDelegate: NetworkingControllerErrorDelegate?
    open var successDelegate: NetworkingControllerSuccessDelegate?
    
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
    func requestDidReceiveAuthenticationChallenge(_ request: URLRequest) -> (username: String, password: String)
    func requestDidFail(_ request: URLRequest, error: NSError, status: URLResponseStatus?)
    func sessionDidFail(_ error: NSError?)
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
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Swift.Void) {
        
        func cancel() {
            challenge.sender?.cancel(challenge)
            completionHandler(.cancelAuthenticationChallenge, .none)
        }
        
        guard let request: URLRequest = task.originalRequest, challenge.previousFailureCount == 0 else {
            cancel()
            return
        }
        
        func performDefaultHanding() {
            challenge.sender?.performDefaultHandling?(for: challenge)
            completionHandler(.performDefaultHandling, .none)
        }
        
        let authenticationMethod: String = challenge.protectionSpace.authenticationMethod
        let credential: URLCredential
        
        func useCredential() {
            challenge.sender?.use(credential, for: challenge)
            completionHandler(.useCredential, credential)
        }
        
        switch authenticationMethod {
        case NSURLAuthenticationMethodHTTPBasic,
             NSURLAuthenticationMethodHTTPDigest:
            // create URLCredential with username/password, ask user for it
            guard let errorDelegate: NetworkingControllerErrorDelegate = self.errorDelegate else {
                performDefaultHanding()
                return
            }
            var usernamePassword: (String, String) = ("","")
            DispatchQueue.main.sync {
                usernamePassword = errorDelegate.requestDidReceiveAuthenticationChallenge(request)
            }
            credential = URLCredential(user: usernamePassword.0, password: usernamePassword.1, persistence: .permanent)
            useCredential()
            
        case NSURLAuthenticationMethodClientCertificate, NSURLAuthenticationMethodServerTrust:
            // create URLCredential with trust
            guard let trust: SecTrust = challenge.protectionSpace.serverTrust, SecTrustGetCertificateCount(trust) > 0,
                let certificate: SecCertificate = SecTrustGetCertificateAtIndex(trust, 0) else {
                cancel()
                return
            }
            let data: Data = SecCertificateCopyData(certificate) as Data
            if self.certificates.contains(data) {
                credential = URLCredential(trust: trust)
                useCredential()
            } else {
                cancel()
            }
            
        default:
            performDefaultHanding()
        }
    }

}

