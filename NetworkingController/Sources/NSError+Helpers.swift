//
//  NSError+Helpers.swift
//  NetworkingController
//
//  Created by Chandler De Angelis on 9/16/17.
//  Copyright © 2017 Chandler De Angelis. All rights reserved.
//

import Foundation

extension NSError {
    
    public static var noInternetConnectionError: NSError {
        let localizedDescription: String = NSLocalizedString("You are not connected to the internet", comment: "")
        return NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: [NSLocalizedDescriptionKey: localizedDescription])
    }
}
