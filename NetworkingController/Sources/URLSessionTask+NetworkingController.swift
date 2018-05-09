//
//  URLSessionTask+NetworkingController.swift
//  NetworkingController
//
//  Created by Chandler De Angelis on 4/6/18.
//  Copyright © 2018 Chandler De Angelis. All rights reserved.
//

import Foundation

extension URLSessionTask {
    
    var responseStatus: URLResponseStatus? {
        let httpResponse = self.response as? HTTPURLResponse
        return httpResponse.flatMap({ URLResponseStatus(rawValue: $0.statusCode) })
    }
}

