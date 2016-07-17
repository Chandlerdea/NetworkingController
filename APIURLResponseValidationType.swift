//
//  APIURLResponseValidationType.swift
//  Spinlister
//
//  Created by Chandler De Angelis on 12/15/15.
//  Copyright © 2015 Spinlister. All rights reserved.
//

import Foundation

public enum APIURLResponseValidationError: ErrorType {
    case UnexpectedStatusCode, UnexpectedMIMEType, InvalidReponse
}

protocol APIURLResponseValidationType {
    var expectedStatus: [URLResponseStatus] { get }
    var expectedMimeType: [API.Request.MIMEType] { get }
    var requestForValidation: NSURLRequest? { get }
    func validateResponse(response: NSURLResponse?) throws
}

extension APIURLResponseValidationType {
    func validateResponse(response: NSURLResponse?) throws {
        guard let httpResponse = response as? NSHTTPURLResponse else { throw APIURLResponseValidationError.InvalidReponse }
        print("\nresponse code for request: \(httpResponse.statusCode)\nURL: \(httpResponse.URL)")
        print("Mime type: \(httpResponse.MIMEType)\n")
        let status = URLResponseStatus(rawValue: httpResponse.statusCode)
        if !expectedStatus.contains(status) {
            throw APIURLResponseValidationError.UnexpectedStatusCode
        }

        if let MIMEType = httpResponse.MIMEType {
            if let type = API.Request.MIMEType(rawValue: MIMEType) {
                if !expectedMimeType.contains(type) {
                    throw APIURLResponseValidationError.UnexpectedMIMEType
                }
            }
        }
    }
}

protocol APIURLResponseJSONType: APIURLResponseValidationType {}
protocol APIURLResponseImageType: APIURLResponseValidationType {}

extension APIURLResponseJSONType {
    var expectedMimeType: [API.Request.MIMEType] { return [.JSON] }

    var expectedStatus: [URLResponseStatus] {
        guard let request = self.requestForValidation else { return [URLResponseStatus]() }
        switch request.HTTPMethod! {
        case API.Request.Method.GET.rawValue:
            return [.OK, .NoContent]
        case API.Request.Method.PUT.rawValue:
            return [.OK, .NoContent]
        case API.Request.Method.POST.rawValue:
            return [.OK, .NoContent, .Created]
        case API.Request.Method.DELETE.rawValue:
            return [.OK, .NoContent, .Accepted]
        default:
            return [URLResponseStatus]()
        }
    }
}

extension APIURLResponseImageType {
    var expectedMimeType: [API.Request.MIMEType] { return [.PNGImage] }

    var expectedStatus: [URLResponseStatus] {
        return [.OK, .Created]
    }
}

