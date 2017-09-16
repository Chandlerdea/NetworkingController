//
//  NetworkingController.swift
//  SpinlisterKit
//
//  Created by Chandler De Angelis on 2/11/16.
//  Copyright © 2016 Spinlister LLC. All rights reserved.
//

import Foundation

open class NetworkingController: NSObject {

    private lazy var session: URLSession = {
        let queue: OperationQueue = OperationQueue()
        queue.maxConcurrentOperationCount = 5
        return URLSession(
            configuration: URLSessionConfiguration.default,
            delegate: self,
            delegateQueue: queue
        )
    }()
    
    private var currentRequest: URLRequest?
    
    var requestForValidation: URLRequest? {
        return self.currentRequest
    }

    private var requests: [Int: URLRequest] = [:]
    private var responseData: [Int: Data] = [:]

    private let responseDataAccessQueue: DispatchQueue = DispatchQueue(label: "com.spinlister.networkingcontroller")

    open var errorDelegate: NetworkingControllerErrorDelegate?
    open var successDelegate: NetworkingControllerSuccessDelegate?
    
    deinit {
        self.session.invalidateAndCancel()
    }

    // Returns the task ID
    public func perform(request: URLRequest) -> Int {
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
    func requestDidFail(_ request: URLRequest, error: NSError, status: URLResponseStatus?)
    func sessionDidFail(_ error: NSError?)
}

public protocol NetworkingControllerSuccessDelegate {
    func requestDidComplete(_ request: URLRequest, data: Data)
}

extension NetworkingController: URLSessionDataDelegate {

    public func urlSession(session: URLSession, dataTask: URLSessionDataTask, didReceiveData data: Data) {
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

    public func urlSession(session: URLSession, task: URLSessionTask, didCompleteWithError error: NSError?) {
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        
        guard let request: URLRequest = self.requests[task.taskIdentifier] else { return }
        
        self.readResponseData({ (allData: inout [Int: Data]) in
            guard let existingData: Data        = allData[task.taskIdentifier],
                let response:       URLResponse = task.response else { return }
            
            do {
                self.currentRequest = request
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

extension NetworkingController: URLSessionDelegate {

    public func urlSession(session: URLSession, didBecomeInvalidWithError error: NSError?) {
        DispatchQueue.main.async {
            self.errorDelegate?.sessionDidFail(error)
        }
    }

//    public func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
//        
//    }

}

