//
//  File.swift
//  
//
//  Created by Inumaki on 14.11.23.
//

import Foundation

class ParserDelegate: NSObject, XMLParserDelegate {
    var package: Package?
    var currentMetadata: Metadata?
    var currentManifest: Manifest?
    var currentSpine: Spine?
    var currentGuide: Guide?
    var currentManifestItem: ManifestItem?
    var currentSpineItem: SpineItem?
    var currentGuideReference: GuideReference?
    var currentElement: String = ""

    func parseXML(xmlString: String) -> Package? {
        let data = xmlString.data(using: .utf8)!
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        return package
    }

    func parserDidStartDocument(_ parser: XMLParser) {
        package = Package(
            metadata: Metadata(title: "", creator: "", publisher: "", date: "", rights: "", source: "", identifier: "", language: "", description: "", format: ""),
            manifest: Manifest(items: []),
            spine: Spine(toc: "", items: []),
            guide: Guide(references: []),
            navElement: NavElement(href: "")
        )
        
        currentMetadata = Metadata(title: "", creator: "", publisher: "", date: "", rights: "", source: "", identifier: "", language: "", description: "", format: "")
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        currentElement = elementName
        switch elementName {
        case "metadata":
            if let currentMetadata = currentMetadata {
                package?.metadata = currentMetadata
            }
            //currentMetadata = nil
        case "meta":
            if let currentMetadata = currentMetadata {
                package?.metadata = currentMetadata
            }
            //currentMetadata = nil
        case "manifest":
            currentManifest = Manifest(items: [])
        case "item":
            let id = attributeDict["id"]
            let href = attributeDict["href"]
            let mediaType = attributeDict["media-type"]
            let properties = attributeDict["properties"]
            
            currentManifestItem = ManifestItem(href: href ?? "", id: id ?? "", mediaType: mediaType ?? "", properties: properties ?? "")
            if currentManifest != nil {
                if let item = currentManifestItem {
                    if item.properties == "nav" {
                        if package != nil {
                            package!.navElement = NavElement(href: item.href)
                        }
                    }
                    
                    currentManifest!.items.append(item)
                }
            }
        case "spine":
            guard let toc = attributeDict["toc"] else { return }
            currentSpine = Spine(toc: toc, items: [])
        case "itemref":
            let idRef = attributeDict["idref"]
            let linear = attributeDict["linear"]
            currentSpineItem = SpineItem(idRef: idRef ?? "", linear: linear ?? "yes")
        case "guide":
            currentGuide = Guide(references: [])
        case "reference":
            guard let href = attributeDict["href"],
                  let title = attributeDict["title"],
                  let type = attributeDict["type"] else { return }
            currentGuideReference = GuideReference(href: href, title: title, type: type)
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let content = string.trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch currentElement {
        case "dc:title":
            currentMetadata?.title += content
        case "dc:creator":
            currentMetadata?.creator += content
        case "dc:publisher":
            currentMetadata?.publisher += content
        case "dc:date":
            currentMetadata?.date += content
        case "dc:rights":
            currentMetadata?.rights += content
        case "dc:source":
            currentMetadata?.source += content
        case "dc:identifier":
            currentMetadata?.identifier += content
        case "dc:language":
            currentMetadata?.language += content
        case "dc:format":
            currentMetadata?.format += content
        case "description":
            currentMetadata?.description += content
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        switch elementName {
        case "metadata":
            package?.metadata = currentMetadata ?? Metadata(title: "", creator: "", publisher: "", date: "", rights: "", source: "", identifier: "", language: "", description: "", format: "")
        case "manifest":
            package?.manifest = currentManifest ?? Manifest(items: [])
        case "item":
            if let manifestItem = currentManifestItem {
                currentManifest?.items.append(manifestItem)
            }
        case "spine":
            package?.spine = currentSpine ?? Spine(toc: "", items: [])
        case "itemref":
            if let spineItem = currentSpineItem {
                currentSpine?.items.append(spineItem)
            }
        case "guide":
            package?.guide = currentGuide ?? Guide(references: [])
        case "reference":
            if let guideReference = currentGuideReference {
                currentGuide?.references.append(guideReference)
            }
        default:
            break
        }
    }
}
