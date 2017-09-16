//
//  APIURLResponseValidationType.swift
//  Spinlister
//
//  Created by Chandler De Angelis on 12/15/15.
//  Copyright © 2015 Spinlister. All rights reserved.
//

import Foundation

public enum APIURLResponseValidationError: Error {
    case unexpectedStatusCode, unexpectedMIMEType, invalidReponse
}

protocol APIURLResponseValidationType {
    var expectedStatus: [URLResponseStatus] { get }
    var expectedMimeType: [MIMEType] { get }
    var requestForValidation: URLRequest? { get }
    func validateResponse(_ response: URLResponse?) throws
}

extension APIURLResponseValidationType {
    
    func validateResponse(_ response: URLResponse?) throws {
        guard let httpResponse: HTTPURLResponse = response as? HTTPURLResponse else {
            throw APIURLResponseValidationError.invalidReponse
            
        }
        
        let status: URLResponseStatus = URLResponseStatus(rawValue: httpResponse.statusCode)
        
        if !self.expectedStatus.contains(status) {
            throw APIURLResponseValidationError.unexpectedStatusCode
        }

        if let responseMimeType: MIMEType = httpResponse.mimeType.flatMap(MIMEType.init(rawValue:)), !self.expectedMimeType.contains(responseMimeType) {
            throw APIURLResponseValidationError.unexpectedMIMEType
        }
    }
}

protocol APIURLResponseJSONType: APIURLResponseValidationType {}
protocol APIURLResponseImageType: APIURLResponseValidationType {}

extension APIURLResponseJSONType {
    
    var expectedMimeType: [MIMEType] {
        return [.json]
    }

    var expectedStatus: [URLResponseStatus] {
        guard let request = self.requestForValidation else { return [URLResponseStatus]() }
        switch request.httpMethod! {
        case HTTPMethod.get.rawValue:
            return [.OK, .NoContent]
        case HTTPMethod.put.rawValue:
            return [.OK, .NoContent]
        case HTTPMethod.post.rawValue:
            return [.OK, .NoContent, .Created]
        case HTTPMethod.delete.rawValue:
            return [.OK, .NoContent, .Accepted]
        default:
            return [URLResponseStatus]()
        }
    }
}

extension APIURLResponseImageType {
    
    var expectedMimeType: [MIMEType] {
        return [.pngImage]
    }

    var expectedStatus: [URLResponseStatus] {
        return [.OK, .Created]
    }
}

