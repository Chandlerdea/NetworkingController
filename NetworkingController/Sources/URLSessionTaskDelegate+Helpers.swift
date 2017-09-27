//
//  URLSessionTaskDelegate+Helpers.swift
//  NetworkingController
//
//  Created by Chandler De Angelis on 9/26/17.
//  Copyright © 2017 Chandler De Angelis. All rights reserved.
//

import Foundation

extension URLSessionTaskDelegate {
    
    func cancel(_ challenge: URLAuthenticationChallenge, completionHandler: (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        challenge.sender?.cancel(challenge)
        completionHandler(.cancelAuthenticationChallenge, .none)
    }
    
    func performDefaultHandling(_ challenge: URLAuthenticationChallenge, completionHandler: (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        challenge.sender?.performDefaultHandling?(for: challenge)
        completionHandler(.performDefaultHandling, .none)
    }
    
    func useCredential(_ credential: URLCredential, challenge: URLAuthenticationChallenge, completionHandler: (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        challenge.sender?.use(credential, for: challenge)
        completionHandler(.useCredential, credential)
    }
}
