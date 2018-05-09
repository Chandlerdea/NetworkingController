//
//  JSONResource.swift
//  NetworkingController
//
//  Created by Chandler De Angelis on 4/7/18.
//  Copyright © 2018 Chandler De Angelis. All rights reserved.
//

import Foundation

public enum JSONResourceError: Error {
    case notASJSONAPIResource
    case wrongType(String)
    case missingAttribute(String)
    
    public var localizedDescription: String {
        switch self {
        case .notASJSONAPIResource:
            return "Not a JSONAPI Resource"
        case .wrongType(let type):
            return "Unexpected resource type: \(type)"
        case .missingAttribute(let attribute):
            return "Missing attribute \(attribute)"
        }
    }
}

public struct JSONResource: JSONAPIResource {
    
    public subscript(relationship rel: String) -> JSONDocument? {
        return self.relationships?[rel]
    }
    
    public subscript<T>(attribute attr: String) -> T? {
        return self.attributes?[attr] as? T
    }
    
    public let json: JSONObject
    private let numberFormatter: NumberFormatter = NumberFormatter()
    
    public init(ID: Int? = nil, type: String, attributes: JSONObject? = nil, relationships: [String: JSONDocument]? = nil) {
        var newJson: JSONObject = ["type": type]
        if let ID: Int = ID {
            newJson["id"] = ID
        }
        if let attrs: JSONObject = attributes {
            newJson["attributes"] = attrs
        }
        if let relationships: [String: JSONDocument] = relationships {
            var newRelationships: JSONObject = [:]
            for (key, value) in relationships {
                newRelationships[key] = value.json
            }
            newJson["relationships"] = newRelationships
        }
        self.json = newJson
    }
    
    public init(json: JSONObject) {
        self.json = json
    }
    
    public var ID: Int? {
        return self["id"].flatMap(toJSONInt)
    }
    
    public var type: String? {
        return self["type"].flatMap(toJSONString)
    }
    
    public var links: JSONObject? {
        return self["links"].flatMap(toJSONObject)
    }
    
    public var attributes: JSONObject? {
        return self["attributes"].flatMap(toJSONObject)
    }
    
    public var relationships: JSONDocument.Relationships? {
        guard let relationships: [String: JSONObject] = self["relationships"] as? [String: JSONObject] else {
            return .none
        }
        var result: JSONDocument.Relationships = [:]
        for (key, value) in relationships {
            result[key] = JSONDocument(json: value)
        }
        return result
    }
    
    public func relatedResources(for resource: JSONResource, in document: JSONDocument) -> [JSONResource] {
        var result: [JSONResource] = []
        if let relationships: JSONDocument.Relationships = self.relationships {
            for (resourceType, doc) in relationships {
                let filter: (JSONResource) -> Bool = { resource in
                    return resource.ID == doc.resourceObject?.ID && resource.type == resourceType
                }
                guard let includedIndex: Int = document.includes.index(where: filter) else {
                    continue
                }
                let includedResource: JSONResource = document.includes[includedIndex]
                result.append(includedResource)
            }
        }
        return result
    }
    
    public var meta: JSONObject? {
        return self["meta"] as? JSONObject
    }
    
    public func relationship(ofType type: AnyObject.Type) -> JSONResource? {
        let key = String(describing: type).lowercased()
        return self.relationships?[key]?.resourceObject
    }
}

