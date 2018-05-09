//
//  JSONDocument.swift
//  NetworkingController
//
//  Created by Chandler De Angelis on 4/6/18.
//  Copyright © 2018 Chandler De Angelis. All rights reserved.
//

import Foundation

public struct JSONDocument: JSONAPIResource {
    
    public typealias Relationships = [String: JSONDocument]
    
    public let json: JSONObject
    
    public var rootDataObject: JSONObject? {
        return self.json["data"] as? JSONObject
    }
    
    init(json: JSONObject) {
        self.json = json
    }
    
    public init(resource: JSONResource) {
        self.json = ["data": resource.json]
    }
    
    init?(data: Data) {
        if let object: Any = try? JSONSerialization.jsonObject(with: data, options: []),
            let json: JSONObject = object as? JSONObject,
            json["data"] != nil {
            self.json = json
        } else {
            return nil
        }
    }
    
    public var resourceObjects: [JSONResource]? {
        guard let objects = self["data"] as? [JSONObject] else {
            return .none
        }
        return objects.map(JSONResource.init)
    }
    
    public var resourceObject: JSONResource? {
        guard let data = self["data"] as? JSONObject else {
            return .none
        }
        return JSONResource(json: data)
    }
    
    public var links: JSONObject? {
        return self["links"] as? JSONObject
    }
    
    public var meta: JSONObject? {
        return self["meta"] as? JSONObject
    }
    
    public var errors: [JSONObject] {
        return self["errors"] as? [JSONObject] ?? []
    }
    
    public var includes: [JSONResource] {
        guard let included = self["included"] as? [JSONObject] else {
            return []
        }
        return included.map(JSONResource.init)
    }
    
}
