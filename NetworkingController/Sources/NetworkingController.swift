//
//  NetworkingController.swift
//  SpinlisterKit
//
//  Created by Chandler De Angelis on 2/11/16.
//  Copyright © 2016 Spinlister LLC. All rights reserved.
//

import Foundation

public protocol NetworkingControllerAuthenticationDelegate: class {
    func requestDidReceiveAuthenticationChallenge(_ request: URLRequest) -> (username: String, password: String)?
    func shouldProceedWithAuthenticationChallendWithoutCredentials(_ request: URLRequest) -> Bool
}

public protocol NetworkingControllerErrorDelegate: class {
    func taskDidFail(_ task: URLSessionTask, error: NSError, status: URLResponseStatus?)
    func sessionDidFail(_ error: NSError?)
}

extension NetworkingControllerErrorDelegate {
    public func requestDidReceiveAuthenticationChallenge(_ request: URLRequest) -> (username: String, password: String)? {
        return .none
    }
    
    public func shouldProceedWithAuthenticationChallendWithoutCredentials(_ request: URLRequest) -> Bool {
        return true
    }
}

public protocol NetworkingControllerSuccessDelegate: class {
    func taskDidComplete(_ task: URLSessionTask, data: Data)
    func taskDidComplete(_ task: URLSessionTask, document: JSONDocument)
}

public typealias NetworkingControllerDelegate = NetworkingControllerSuccessDelegate & NetworkingControllerErrorDelegate & NetworkingControllerAuthenticationDelegate

public final class AnyNetworkingControllerDelegate: NetworkingControllerDelegate {
    
    private let _taskDidFail: (URLSessionTask, NSError, URLResponseStatus?) -> Void
    private let _sessionDidfail: (NSError?) -> Void
    private let _taskDidCompleteWithData: (URLSessionTask, Data) -> Void
    private let _taskDidCompleteWithDocument: (URLSessionTask, JSONDocument) -> Void
    private let _didReceiveAuthChallenge: (URLRequest) -> (String, String)?
    private let _shouldProceedWithoutCredentials: (URLRequest) -> Bool
    
    public init(_ delegate: NetworkingControllerDelegate) {
        self._taskDidFail = delegate.taskDidFail
        self._sessionDidfail = delegate.sessionDidFail
        self._taskDidCompleteWithData = delegate.taskDidComplete
        self._taskDidCompleteWithDocument = delegate.taskDidComplete
        self._didReceiveAuthChallenge = delegate.requestDidReceiveAuthenticationChallenge
        self._shouldProceedWithoutCredentials = delegate.shouldProceedWithAuthenticationChallendWithoutCredentials
    }
    
    public func taskDidFail(_ task: URLSessionTask, error: NSError, status: URLResponseStatus?) {
        self._taskDidFail(task, error, status)
    }
    
    public func sessionDidFail(_ error: NSError?) {
        self._sessionDidfail(error)
    }
    
    public func taskDidComplete(_ task: URLSessionTask, data: Data) {
        self._taskDidCompleteWithData(task, data)
    }
    
    public func taskDidComplete(_ task: URLSessionTask, document: JSONDocument) {
        self._taskDidCompleteWithDocument(task, document)
    }
    
    public func requestDidReceiveAuthenticationChallenge(_ request: URLRequest) -> (username: String, password: String)? {
        return self._didReceiveAuthChallenge(request)
    }
    
    public func shouldProceedWithAuthenticationChallendWithoutCredentials(_ request: URLRequest) -> Bool {
        return self._shouldProceedWithoutCredentials(request)
    }
}

open class NetworkingController: NSObject {
    
    private typealias Request = (URLRequest, NetworkingControllerDelegate)
    
    private static var sessionDelegate: NetworkingControllerSessionDelegate {
        return self.session.delegate as! NetworkingControllerSessionDelegate
    }
    private static var session: URLSession = URLSession(configuration: .default, delegate: NetworkingControllerSessionDelegate(), delegateQueue: .none)
    
    private var _requestForValidation: URLRequest?
    
    var requestForValidation: URLRequest? {
        return self._requestForValidation
    }

    private var requests: [Int: Request] = [:]
    private var responseData: [Int: Data] = [:]

    private let responseDataAccessQueue: DispatchQueue = DispatchQueue(label: "com.spinlister.networkingcontroller")
    
    private let serverTrustDelegate: ServerTrustDelegate = ServerTrustDelegate()
    private let basicAuthDelegate: HTTPBasicAuthDelegate = HTTPBasicAuthDelegate()
    
    static func configureForTesting(with urlProtocolClass: URLProtocol.Type) {
        let configuration: URLSessionConfiguration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [urlProtocolClass]
        self.session =  URLSession(
            configuration: configuration,
            delegate: NetworkingControllerSessionDelegate(),
            delegateQueue: OperationQueue()
        )
    }
    
    public override init() {
        super.init()
        NetworkingController.sessionDelegate.addController(self)
    }
    
    deinit {
        NetworkingController.sessionDelegate.removeNilControllers()
    }
    
    func delegate(for task: URLSessionTask) -> NetworkingControllerDelegate? {
        return self.requests[task.taskIdentifier]?.1
    }

    // Returns the task ID
    @discardableResult public func send(_ request: URLRequest, delegate: NetworkingControllerDelegate) -> Int {
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        
        let dataTask: URLSessionDataTask = NetworkingController.session.dataTask(with: request)
        self.requests[dataTask.taskIdentifier] = (request, AnyNetworkingControllerDelegate(delegate))
        
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

    private func throwReachabilityError(for task: URLSessionTask) {
        DispatchQueue.main.async {
            let error: NSError = NSError.noInternetConnectionError
            self.delegate(for: task)?.taskDidFail(task, error: error, status: .none)
        }
    }

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
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
        guard let request: URLRequest = self.requests[task.taskIdentifier]?.0 , error == nil else {
            DispatchQueue.main.async {
                guard let error: Error = error else { return }
                self.delegate(for: task)?.taskDidFail(task, error: error as NSError, status: .none)
            }
            self.requests.removeValue(forKey: task.taskIdentifier)
            return
        }
        let status: URLResponseStatus? = task.responseStatus
        self.readResponseData({ [weak self] (mutableData) in
            defer {
                self?.requests.removeValue(forKey: task.taskIdentifier)
            }
            guard let strongSelf: NetworkingController = self, let existingData: Data = mutableData[task.taskIdentifier], let response = task.response, let delegate: NetworkingControllerDelegate = strongSelf.delegate(for: task) else {
                return
            }
            do {
                strongSelf._requestForValidation  = request
                if let validation = strongSelf as? APIURLResponseValidationType {
                    try validation.validateResponse(response)
                }
                if type(of: strongSelf) == JSONNetworkingController.self {
                    if status != .NoContent {
                        if let document: JSONDocument = JSONDocument(data: existingData) {
                            DispatchQueue.global().async {
                                delegate.taskDidComplete(task, document: document)
                            }
                        } else {
                            DispatchQueue.global().async {
                                delegate.taskDidComplete(task, data: existingData)
                            }
                        }
                    } else {
                        DispatchQueue.global().async {
                            delegate.taskDidComplete(task, data: existingData)
                        }
                    }
                } else {
                    DispatchQueue.global().async {
                        delegate.taskDidComplete(task, data: existingData)
                    }
                }
            } catch {
                var errorUserInfo: [String: AnyObject] = [:]
                switch status?.rawValue {
                case  NSURLErrorTimedOut?:
                    errorUserInfo[NSLocalizedDescriptionKey] = NSLocalizedString("The connection timed out, checkout your internet connection and try again", comment: "") as AnyObject?
                default:
                    if let json = try? JSONSerialization.jsonObject(with: existingData as Data, options: []) as? JSONObject {
                        let title: String?
                        let message: String?
                        if let info: JSONObject = json?["errors"].flatMap(toJSONObjectArray)?.first {
                            title = info["title"].flatMap(toJSONString)
                            message = info["detail"].flatMap(toJSONString)
                        } else {
                            title = NSLocalizedString("Unknown error", comment: "")
                            message = NSLocalizedString("An unknown error occurred", comment: "")
                        }
                        errorUserInfo[NSLocalizedDescriptionKey] = title as AnyObject
                        errorUserInfo[NSLocalizedFailureReasonErrorKey] = message as AnyObject
                    } else {
                        errorUserInfo[NSLocalizedDescriptionKey] = NSLocalizedString("An unknown error occurred", comment: "") as AnyObject
                    }
                }
                let urlError = NSError(domain: "com.surgio.NetworkingController", code: 0, userInfo: errorUserInfo)
                DispatchQueue.global().async {
                    delegate.taskDidFail(task, error: urlError, status: status)
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
            self.basicAuthDelegate.authDelegate = self.delegate(for: task)
            self.basicAuthDelegate.urlSession(session, task: task, didReceive: challenge, completionHandler: completionHandler)
            self.basicAuthDelegate.authDelegate = .none
            
        case NSURLAuthenticationMethodClientCertificate:
            // client provides cert for server to verify
            // but the client should also verify the cert from the server, if the server sends it
            fallthrough
            
        case NSURLAuthenticationMethodServerTrust:
            // server provides cert for client to verify
            self.serverTrustDelegate.authDelegate = self.delegate(for: task)
            self.serverTrustDelegate.urlSession(session, task: task, didReceive: challenge, completionHandler: completionHandler)
            self.serverTrustDelegate.authDelegate = .none
            
        default:
            self.performDefaultHandling(challenge, completionHandler: completionHandler)
        }
    }

}

