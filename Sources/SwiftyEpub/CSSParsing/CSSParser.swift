//
//  CSSParser.swift
//
//
//  Created by Inumaki on 06.01.24.
//

import Foundation

public struct CSSParser {
    // Struct to hold CSS properties
    private struct CSSRule {
        let selector: String
        let properties: [String: String]
    }

    private var parsedCSS: [CSSRule] = []

    public init(cssString: String) {
        parseCSS(cssString: cssString)
    }

    private mutating func parseCSS(cssString: String) {
        // Split the CSS string into individual rules
        let ruleStrings = cssString.components(separatedBy: "}")
        
        for ruleString in ruleStrings {
            // Extract the selector and properties from each rule string
            let components = ruleString.components(separatedBy: "{")
            if components.count == 2 {
                let selector = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let propertiesString = components[1]
                let properties = parseProperties(propertiesString)
                
                // Create a CSSRule instance and append it to the parsedCSS array
                let rule = CSSRule(selector: selector, properties: properties)
                parsedCSS.append(rule)
            }
        }
    }

    private func parseProperties(_ propertiesString: String) -> [String: String] {
        // Implement logic to parse the properties from propertiesString
        // This might involve tokenizing the properties string and creating a dictionary
        
        // Example logic (to be replaced with actual parsing logic)
        let propertyPairs = propertiesString.components(separatedBy: ";")
        var parsedProperties: [String: String] = [:]
        for pair in propertyPairs {
            let property = pair.components(separatedBy: ":")
            if property.count == 2 {
                let key = property[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let value = property[1].trimmingCharacters(in: .whitespacesAndNewlines)
                parsedProperties[key] = value
            }
        }
        return parsedProperties
    }

    // Function to get all CSS properties based on selector
    public func getProperties(for selector: String) -> [String: String] {
        // Match selector against parsed CSS data structure
        // Retrieve properties associated with the matched selector
        // Return properties as a dictionary
        
        // Example logic (to be replaced with actual selector matching logic)
        for rule in parsedCSS {
            if rule.selector == selector {
                return rule.properties
            }
        }
        return [:] // Return an empty dictionary if no properties found
    }
}
