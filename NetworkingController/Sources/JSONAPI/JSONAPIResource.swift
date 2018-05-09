//
//  JSONAPIResource.swift
//  NetworkingController
//
//  Created by Chandler De Angelis on 4/7/18.
//  Copyright © 2018 Chandler De Angelis. All rights reserved.
//

import Foundation

protocol JSONAPIResource {
    var json: JSONObject { get }
    subscript(key: String) -> JSON? { get }
}

extension JSONAPIResource {
    subscript(key: String) -> JSON? {
        get {
            return self.json[key]
        }
    }
}
