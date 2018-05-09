//
//  URLSessionDelegate.swift
//  NetworkingController
//
//  Created by Chandler De Angelis on 5/7/18.
//  Copyright © 2018 Chandler De Angelis. All rights reserved.
//

import Foundation

final class WeakBox<A: AnyObject> {
    weak var unbox: A?
    init(_ value: A) {
        self.unbox = value
    }
}

final class NetworkingControllerSessionDelegate: NSObject, URLSessionTaskDelegate, URLSessionDataDelegate {
    
    private var controllers: [WeakBox<NetworkingController>] = []
    
    func addController(_ controller: NetworkingController) {
        self.controllers.append(WeakBox(controller))
    }
    
    func removeNilControllers() {
        self.controllers = self.controllers.filter { $0.unbox != nil }
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        for controller in self.controllers where controller.unbox != nil {
            controller.unbox?.urlSession(session, dataTask: dataTask, didReceive: data)
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        for controller in self.controllers where controller.unbox != nil {
            controller.unbox?.urlSession(session, task: task, didCompleteWithError: error)
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        for controller in self.controllers where controller.unbox != nil {
            controller.unbox?.urlSession(session, task: task, didReceive: challenge, completionHandler: completionHandler)
        }
    }

}
