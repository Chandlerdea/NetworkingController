//
//  URLResponseStatus.swift
//  Spinlister
//
//  Created by Chandler De Angelis on 1/5/16.
//  Copyright © 2016 Spinlister. All rights reserved.
//

import Foundation

public struct URLResponseStatus: OptionSetType {
    public let rawValue: Int
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let OK               = URLResponseStatus(rawValue: 200)
    public static let Created          = URLResponseStatus(rawValue: 201)
    public static let Accepted         = URLResponseStatus(rawValue: 202)
    public static let NoContent        = URLResponseStatus(rawValue: 204)
    public static let BadRequest       = URLResponseStatus(rawValue: 400)
    public static let Unauthorized     = URLResponseStatus(rawValue: 401)
    public static let Forbidden        = URLResponseStatus(rawValue: 403)
    public static let NotFound         = URLResponseStatus(rawValue: 404)
    public static let Gone             = URLResponseStatus(rawValue: 410)
    public static let ServerError      = URLResponseStatus(rawValue: 500)
}

extension URLResponseStatus: Equatable { }
extension URLResponseStatus: Comparable { }

public func ==(lhs: URLResponseStatus, rhs: URLResponseStatus) -> Bool {
    return lhs.rawValue == rhs.rawValue
}

public func >(lhs: URLResponseStatus, rhs: URLResponseStatus) -> Bool {
    return lhs.rawValue > rhs.rawValue
}

public func <(lhs: URLResponseStatus, rhs: URLResponseStatus) -> Bool {
    return lhs.rawValue < rhs.rawValue
}

public func >=(lhs: URLResponseStatus, rhs: URLResponseStatus) -> Bool {
    return lhs.rawValue >= rhs.rawValue
}

public func <=(lhs: URLResponseStatus, rhs: URLResponseStatus) -> Bool {
    return lhs.rawValue <= rhs.rawValue
}
