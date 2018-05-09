//
//  PublicKeyPinningDelegate.swift
//  NetworkingController
//
//  Created by Chandler De Angelis on 9/26/17.
//  Copyright © 2017 Chandler De Angelis. All rights reserved.
//

import Foundation


final class ServerTrustDelegate: NSObject, URLSessionTaskDelegate {
    
    weak var authDelegate: NetworkingControllerAuthenticationDelegate?
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let protectionSpace: URLProtectionSpace = challenge.protectionSpace
        var shouldProceedWithoutCredentials: Bool = false
        if let request: URLRequest = task.originalRequest, let authDelegate: NetworkingControllerAuthenticationDelegate = self.authDelegate {
            DispatchQueue.main.sync {
                shouldProceedWithoutCredentials = authDelegate.shouldProceedWithAuthenticationChallendWithoutCredentials(request)
            }
        }
        if let credential: URLCredential = self.credentialForServerTrust(in: protectionSpace) {
            self.useCredential(credential, challenge: challenge, completionHandler: completionHandler)
        } else if shouldProceedWithoutCredentials {
            self.performDefaultHandling(challenge, completionHandler: completionHandler)
        } else {
            self.cancel(challenge, completionHandler: completionHandler)
        }
    }
}

private extension ServerTrustDelegate {
    
    func credentialForServerTrust(in protectionSpace: URLProtectionSpace) -> URLCredential? {
        var result: URLCredential? = URLCredentialStorage.shared.defaultCredential(for: protectionSpace)
        if let trust: SecTrust = protectionSpace.serverTrust, result == .none {
            var trustResult: SecTrustResultType = .fatalTrustFailure
            let status: OSStatus = SecTrustEvaluate(trust, &trustResult)
            if status == errSecSuccess {
                switch trustResult {
                case .proceed,
                     .unspecified:
                    guard self.canAllowServerTrust(for: protectionSpace) else { break }
                    result = URLCredential(trust: trust)
                    URLCredentialStorage.shared.set(result!, for: protectionSpace)
                default:
                    break
                }
            }
        }
        return result
    }
    
    func canAllowServerTrust(for protectionSpace: URLProtectionSpace) -> Bool {
        guard let serverTrust:      SecTrust        = protectionSpace.serverTrust,
            let localCertificate:   SecCertificate  = self.localCertificate(for: protectionSpace.host) else {
                return false
        }
        
        let anchorCertificates: [SecCertificate] = [localCertificate]
        
        SecTrustSetAnchorCertificates(serverTrust, anchorCertificates as CFArray)
        SecTrustSetAnchorCertificatesOnly(serverTrust, true)
        
        var trustResult: SecTrustResultType = .fatalTrustFailure
        let status: OSStatus = SecTrustEvaluate(serverTrust, &trustResult)
        return ((status == noErr) && (trustResult == .unspecified)) || (trustResult == .proceed)
    }
    
    func localCertificate(for host: String) -> SecCertificate? {
        let bundle: Bundle = Bundle(for: type(of: self))
        guard let certificateUrl: URL = bundle.url(forResource: host, withExtension: "der") else {
            return .none
        }
        if let certificateData: Data = try? Data(contentsOf: certificateUrl) {
            return SecCertificateCreateWithData(kCFAllocatorDefault, certificateData as CFData)
        } else {
            return .none
        }
    }
}
