//
//  JSON.swift
//  The Benefit
//
//  Created by Chandler De Angelis on 12/26/16.
//  Copyright © 2016 The Benefit. All rights reserved.
//

import Foundation

typealias JSON = Any
typealias JSONDictionary = [String: JSON]
typealias JSONArray = [JSON]

func JSONString(_ object: JSON) -> String? {
    guard let string: String = object as? String, string.characters.count > 0 else { return .none }
    return string
}

func JSONBoolString(_ object: JSON) -> Bool? {
    if let number = object as? NSNumber {
        return number.boolValue
    } else {
        return (object as? NSString).flatMap({ $0.boolValue })
    }
}

func JSONInt(_ object: JSON) -> Int? {
    if let string = object as? String {
        let formatter = NumberFormatter()
        return formatter.number(from: string)?.intValue
    } else {
        return object as? Int
    }
}

func JSONDouble(_ object: JSON) -> Double? {
    return object as? Double
}

func JSONDecimal(_ object: JSON) -> Decimal? {
    if let string = object as? String {
        let formatter = NumberFormatter()
        return formatter.number(from: string).flatMap({ Decimal($0.doubleValue) })
    } else {
        return (object as? Double).flatMap({ Decimal($0) })
    }
}

func JSONArrayObject(_ object: JSON) -> JSONArray? {
    return object as? JSONArray
}

func JSONObject(_ object: JSON) -> JSONDictionary? {
    return object as? JSONDictionary
}

func JSONObjectArray(_ object: JSON) -> [JSONDictionary]? {
    return object as? [JSONDictionary]
}



