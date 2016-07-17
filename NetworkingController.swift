//
//  NetworkingController.swift
//  SpinlisterKit
//
//  Created by Chandler De Angelis on 2/11/16.
//  Copyright © 2016 Spinlister LLC. All rights reserved.
//

import Foundation

public class NetworkingController: NSObject {

    let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
    private lazy var session: NSURLSession = NSURLSession(configuration: self.configuration, delegate: self, delegateQueue: self.delegateQueue)
    private let delegateQueue = NSOperationQueue()

    private(set) var currentRequest: NSURLRequest?
    var requestForValidation: NSURLRequest? {
        return self.currentRequest
    }

    private(set) var requests = [Int: NSURLRequest]()
    private(set) var responseData = [Int: NSMutableData]()

    private let responseDataAccessQueue = dispatch_queue_create("com.spinlister.networkingcontroller", DISPATCH_QUEUE_SERIAL)

    var errorDelegate: NetworkingControllerErrorDelegate?
    var successDelegate: NetworkingControllerSuccessDelegate?

    public override init() {
        self.delegateQueue.maxConcurrentOperationCount = 5
    }

    // Returns the task ID
    func performTask(request: NSURLRequest) -> Int {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        let dataTask = self.session.dataTaskWithRequest(request)
        self.requests[dataTask.taskIdentifier] = request
        self.readResponseData({ (mutableData) in
            mutableData[dataTask.taskIdentifier] = NSMutableData()
        }) {
            dataTask.resume()
        }
        return dataTask.taskIdentifier
    }

    func readResponseData(closure: (inout mutableData: [Int: NSMutableData]) -> Void, completion: (() -> Void)? = nil) {
        dispatch_barrier_async(self.responseDataAccessQueue) {
            closure(mutableData: &self.responseData)
            completion?()
        }
    }

    private func throwReachabilityError(withRequest request: NSURLRequest) {
        dispatch_async(dispatch_get_main_queue()) {
            let error = NSError.noInternetConnectionError
            self.errorDelegate?.requestDidFail(request, error: error, status: .None)
        }
    }

}

protocol NetworkingControllerErrorDelegate {
    func requestDidFail(request: NSURLRequest, error: NSError, status: URLResponseStatus?)
    func sessionDidFail(error: NSError?)
}

protocol NetworkingControllerSuccessDelegate {
    func requestDidComplete(request: NSURLRequest, data: NSData)
}

extension NetworkingController: NSURLSessionDataDelegate {

    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        self.readResponseData({ (mutableData) in
            guard let existingData = mutableData[dataTask.taskIdentifier] else {
                mutableData[dataTask.taskIdentifier] = NSMutableData(data: data)
                return
            }
            existingData.appendData(data)
        })
    }

    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        guard let request = self.requests[task.taskIdentifier] else {
            return
        }
        self.readResponseData({ (mutableData) in
            guard let existingData = mutableData[task.taskIdentifier], response = task.response else {
                return
            }
            do {
                self.currentRequest = request
                if let validation = self as? APIURLResponseValidationType {
                    try validation.validateResponse(response)
                }
                self.successDelegate?.requestDidComplete(request, data: existingData)
            } catch {
                let status = (task.response as? NSHTTPURLResponse).flatMap({ URLResponseStatus(rawValue: $0.statusCode) })
                var errorUserInto: [String: AnyObject] = [:]
                if let json = try? NSJSONSerialization.JSONObjectWithData(existingData, options: []) as? JSONDictionary {
                    let errorString = json?["error"].flatMap(JSONObjectArray)?.first as? String ??  NSLocalizedString("An unknown error occurred", comment: "")
                    errorUserInto[NSLocalizedDescriptionKey] = errorString
                } else {
                    errorUserInto[NSLocalizedDescriptionKey] = NSLocalizedString("An unknown error occurred", comment: "")
                }
                let URLError = NSError(domain: "com.spinlister.NetworkingController", code: 0, userInfo: errorUserInto)
                self.errorDelegate?.requestDidFail(request, error: URLError, status: status)
                return
            }
        })
    }
}

extension NetworkingController: NSURLSessionDelegate {

    public func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?) {
        self.errorDelegate?.sessionDidFail(error)
    }

//    public func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
//        
//    }

}

