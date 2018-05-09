//
//  JSON.swift
//  The Benefit
//
//  Created by Chandler De Angelis on 12/26/16.
//  Copyright © 2016 The Benefit. All rights reserved.
//

import Foundation

public typealias JSON = Any
public typealias JSONObject = [String: JSON]
public typealias JSONArray = [JSON]

func toJSONString(_ object: JSON) -> String? {
    if let string: String = object as? String, string.count > 0 {
        return string
    } else {
        return .none
    }
}

func toJSONBoolString(_ object: JSON) -> Bool? {
    if let number = object as? NSNumber {
        return number.boolValue
    } else {
        return (object as? NSString).flatMap({ $0.boolValue })
    }
}

func toJSONInt(_ object: JSON) -> Int? {
    if let string = object as? String {
        let formatter = NumberFormatter()
        return formatter.number(from: string)?.intValue
    } else {
        return object as? Int
    }
}

func toJSONDouble(_ object: JSON) -> Double? {
    return object as? Double
}

func toJSONDecimal(_ object: JSON) -> Decimal? {
    if let string = object as? String {
        let formatter = NumberFormatter()
        return formatter.number(from: string).flatMap({ Decimal($0.doubleValue) })
    } else {
        return (object as? Double).flatMap({ Decimal($0) })
    }
}

func toJSONArrayObject(_ object: JSON) -> JSONArray? {
    return object as? JSONArray
}

func toJSONObject(_ object: JSON) -> JSONObject? {
    return object as? JSONObject
}

func toJSONObjectArray(_ object: JSON) -> [JSONObject]? {
    return object as? [JSONObject]
}



