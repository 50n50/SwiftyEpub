// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import ZIPFoundation
import SwiftSoup

extension String {
    func stringByRemovingHTMLTags() -> String {
        return self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
    }
}

public struct SwiftyEpub {
    public var metadata: Metadata? = nil
    public var spine: Spine? = nil
    public var manifest: Manifest? = nil
    public var parsedSpines: [ParsedSpine] = []
    
    public init() {}

    // Function to extract and parse CSS properties
    func extractAndParseCSS(cssString: String, forSelector selector: String) -> [CSSProperty]? {
        let regexString = "\(selector)\\s*\\{([^\\}]*)\\}"
        
        do {
            let regex = try NSRegularExpression(pattern: regexString, options: [])
            let matches = regex.matches(in: cssString, options: [], range: NSRange(location: 0, length: cssString.utf16.count))
            
            if let match = matches.first {
                let range = match.range(at: 1)
                if let swiftRange = Range(range, in: cssString) {
                    let content = String(cssString[swiftRange])
                    let properties = content.components(separatedBy: ";").compactMap { property -> CSSProperty? in
                        let components = property.components(separatedBy: ":")
                        if components.count == 2 {
                            let propertyName = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                            let propertyValue = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                            return CSSProperty(name: propertyName, value: propertyValue)
                        }
                        return nil
                    }
                    return properties
                }
            }
        } catch {
            print("Error: \(error)")
        }
        return nil
    }
    
    public mutating func parseEpub(atPath path: String) {
        let fileManager = FileManager.default
        
        // Check if the file exists at the specified path
        guard fileManager.fileExists(atPath: path) else {
            print("file doesnt exist")
            return
        }
        // Check if the file has the .epub extension
        guard path.lowercased().hasSuffix(".epub") else { return }
        
        // Get the documents directory
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        if fileManager.fileExists(atPath: documentsDirectory.appendingPathComponent("cover.jpg").path) {
            do {
                try fileManager.removeItem(at: documentsDirectory.appendingPathComponent("cover.jpg"))
            } catch {
                print(error.localizedDescription)
            }
        }
        
        // Create a folder name for extracting EPUB
        let extractionFolderName = "EpubExtraction"
        
        // Append the extraction folder path to the documents directory
        let extractionFolderPath = documentsDirectory.appendingPathComponent(extractionFolderName, isDirectory: true)
        
        // Check if the extraction folder exists, if not, create it
        if !fileManager.fileExists(atPath: extractionFolderPath.path) {
            do {
                try fileManager.createDirectory(at: extractionFolderPath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Failed to create extraction folder: \(error)")
                return
            }
        }
        
        print("unzipping")
        
        // Create a subfolder name for the EPUB content within the extraction folder
        let epubFolderName = "ExtractedEPUB"
        let epubFolderPath = extractionFolderPath.appendingPathComponent(epubFolderName, isDirectory: true)
        
        do {
            try fileManager.removeItem(at: epubFolderPath)
        } catch {
            print(error.localizedDescription)
        }
        
        var folderName = "OPS"
        var opfFileName = "package.opf"
        var version = 3
        
        // Unzip the EPUB file into the subfolder within the extraction folder
        do {
            try fileManager.unzipItem(at: URL(fileURLWithPath: path), to: epubFolderPath)
            
            // TODO: Support different EPUB formats
            // Find the content.opf file within the unzipped folder
            
            let container = epubFolderPath.appendingPathComponent("META-INF").appendingPathComponent("container.xml")
            
            // Read the contents of the content.opf file as a string
            let containerString = try String(contentsOf: container, encoding: .utf8)
            
            let pattern = "full-path=\"([^\"]*)\""
            let regex = try! NSRegularExpression(pattern: pattern, options: [])

            if let match = regex.firstMatch(in: containerString, options: [], range: NSRange(location: 0, length: containerString.utf16.count)) {
                let range = match.range(at: 1)
                if let swiftRange = Range(range, in: containerString) {
                    let fullPath = containerString[swiftRange]
                    let split = fullPath.split(separator: "/")
                    
                    print(split)
                    
                    if split.count == 2 {
                        folderName = String(split[0])
                        opfFileName = String(split[1])
                    } else if split.count == 1 && split[0].contains(".opf") {
                        version = 2
                        opfFileName = String(split[0])
                    }
                }
            }
            
            let contentOpfURL = version == 3 ? epubFolderPath.appendingPathComponent(folderName).appendingPathComponent("\(opfFileName)") : epubFolderPath.appendingPathComponent("\(opfFileName)")
            
            // Read the contents of the content.opf file as a string
            let contentOpfString = try String(contentsOf: contentOpfURL, encoding: .utf8)
            
            let parserDelegate = ParserDelegate()

            // Parse the XML string
            if let parsedPackage = parserDelegate.parseXML(xmlString: contentOpfString) {
                metadata = parsedPackage.metadata
                spine = parsedPackage.spine
                manifest = parsedPackage.manifest
                
                // parse the html of the first html file
                if let manifest {
                    let cover = manifest.items.first(where: { element in
                        element.id.contains("cover") && element.mediaType.contains("image")
                    })
                    
                    if let cover {
                        let coverUrl = version == 3 ?  epubFolderPath.appendingPathComponent(folderName).appendingPathComponent(cover.href) : epubFolderPath.appendingPathComponent(cover.href)
                        
                        if !fileManager.fileExists(atPath: path.replacingOccurrences(of: ".epub", with: ".jpg")) {
                            try fileManager.copyItem(at: coverUrl, to: URL(string: "file://" + path.replacingOccurrences(of: ".epub", with: ".jpg"))!)
                        }
                    }
                    
                    // Find the content.opf file within the unzipped folder
                    let cssPath = manifest.items.filter { element in
                        element.id.contains("style")
                    }.first
                    
                    var cssString: String? = nil
                    
                    if let cssPath {
                        let cssURL = version == 3 ? epubFolderPath.appendingPathComponent(folderName).appendingPathComponent(cssPath.href) : epubFolderPath.appendingPathComponent(cssPath.href)
                        
                        cssString = try String(contentsOf: cssURL, encoding: .utf8)
                    }
                    
                    
                    let htmlArray = manifest.items.filter { element in
                        element.mediaType.contains("html")
                    }
                    
                    var parsedHtmlHrefs: [String] = []
                    
                    for html in htmlArray {
                        if !parsedHtmlHrefs.contains(html.href) {
                            // Read HTML content from the local file
                            let opsFolder = version == 3 ? epubFolderPath.appendingPathComponent(folderName) : epubFolderPath
                            
                            let htmlContent = try String(contentsOfFile: opsFolder.appendingPathComponent(html.href).absoluteString.replacingOccurrences(of: "file://", with: ""), encoding: .utf8)
                            
                            parsedHtmlHrefs.append(html.href)
                            
                            do {
                                let doc: Document = try SwiftSoup.parse(htmlContent)
                                let title: String? = try doc.title()

                                var list: [Tag] = []

                                // Find all elements in the document
                                let elements: Elements? = try doc.body()?.select("*")
                                
                                if let elements {
                                    // Iterate through all elements
                                    for element in elements {
                                        
                                        // Check if the element is an <h2> tag
                                        if element.tagName() == "h2" {
                                            
                                            var fontSize: Double = 22.0
                                            var margin: Margin = Margin()
                                            var align: Align = .leading
                                            
                                            if let cssString {
                                                if let parsedProperties = extractAndParseCSS(cssString: cssString, forSelector: ".\(try element.className())") {
                                                    for property in parsedProperties {
                                                        if property.name == "font-size" {
                                                            let multiplier = property.value.replacingOccurrences(of: "em", with: "")
                                                            
                                                            let size: Double = 16.0 * (Double(multiplier) ?? 1.0)
                                                            fontSize = size
                                                        } else if property.name.contains("margin") {
                                                            if property.name.contains("top") {
                                                                let multiplier = property.value.replacingOccurrences(of: "em", with: "")
                                                                
                                                                let size: Double = 16.0 * (Double(multiplier) ?? 1.0)
                                                                margin.top = size
                                                            } else if property.name.contains("bottom") {
                                                                let multiplier = property.value.replacingOccurrences(of: "em", with: "")
                                                                
                                                                let size: Double = 16.0 * (Double(multiplier) ?? 1.0)
                                                                margin.bottom = size
                                                            } else if property.name.contains("left") {
                                                                let multiplier = property.value.replacingOccurrences(of: "em", with: "")
                                                                
                                                                let size: Double = 16.0 * (Double(multiplier) ?? 1.0)
                                                                margin.left = size
                                                            } else if property.name.contains("right") {
                                                                let multiplier = property.value.replacingOccurrences(of: "em", with: "")
                                                                
                                                                let size: Double = 16.0 * (Double(multiplier) ?? 1.0)
                                                                margin.right = size
                                                            }
                                                        } else if property.name == "text-align" {
                                                            if property.value == "center" {
                                                                align = .center
                                                            } else if property.value == "start" {
                                                                align = .leading
                                                            } else if property.value == "end" {
                                                                align = .trailing
                                                            }
                                                        }
                                                        //print("Property Name: \(property.name), Value: \(property.value)")
                                                    }
                                                }
                                            }
                                            
                                            let h2Tag = Tag(type: .h2, value: try element.text(), fontSize: fontSize, margin: margin, align: align)
                                            list.append(h2Tag)
                                            continue
                                        }
                                        
                                        if element.tagName() == "h4" {
                                            
                                            var fontSize: Double = 14.0
                                            var margin: Margin = Margin()
                                            var align: Align = .leading
                                            
                                            if let cssString {
                                                if let parsedProperties = extractAndParseCSS(cssString: cssString, forSelector: ".\(try element.className())") {
                                                    for property in parsedProperties {
                                                        if property.name == "font-size" {
                                                            let multiplier = property.value.replacingOccurrences(of: "em", with: "")
                                                            
                                                            let size: Double = 16.0 * (Double(multiplier) ?? 1.0)
                                                            fontSize = size
                                                        } else if property.name.contains("margin") {
                                                            if property.name.contains("top") {
                                                                let multiplier = property.value.replacingOccurrences(of: "em", with: "")
                                                                
                                                                let size: Double = 16.0 * (Double(multiplier) ?? 1.0)
                                                                margin.top = size
                                                            } else if property.name.contains("bottom") {
                                                                let multiplier = property.value.replacingOccurrences(of: "em", with: "")
                                                                
                                                                let size: Double = 16.0 * (Double(multiplier) ?? 1.0)
                                                                margin.bottom = size
                                                            } else if property.name.contains("left") {
                                                                let multiplier = property.value.replacingOccurrences(of: "em", with: "")
                                                                
                                                                let size: Double = 16.0 * (Double(multiplier) ?? 1.0)
                                                                margin.left = size
                                                            } else if property.name.contains("right") {
                                                                let multiplier = property.value.replacingOccurrences(of: "em", with: "")
                                                                
                                                                let size: Double = 16.0 * (Double(multiplier) ?? 1.0)
                                                                margin.right = size
                                                            }
                                                        } else if property.name == "text-align" {
                                                            if property.value == "center" {
                                                                align = .center
                                                            } else if property.value == "start" {
                                                                align = .leading
                                                            } else if property.value == "end" {
                                                                align = .trailing
                                                            }
                                                        }
                                                        //print("Property Name: \(property.name), Value: \(property.value)")
                                                    }
                                                }
                                            }
                                            
                                            let h4Tag = Tag(type: .h4, value: try element.text(), fontSize: fontSize, margin: margin, align: align)
                                            list.append(h4Tag)
                                            continue
                                        }
                                        
                                        // Check if the element is an <h2> tag
                                        if element.tagName() == "li" {
                                            let liTag = Tag(type: .li, value: try element.text())
                                            list.append(liTag)
                                            continue
                                        }
                                        
                                        // Check if the element is an <h2> tag
                                        if element.tagName() == "img" {
                                            let imgTag = Tag(type: .img, value: try element.attr("src").replacingOccurrences(of: "../", with: ""))
                                            list.append(imgTag)
                                            continue
                                        }
                                        
                                        // Check if the element is a <p> tag
                                        if element.tagName() == "p" {
                                            var str = try element.html()
                                            
                                            var hasSpan: Bool = false
                                            if str.contains("<span") {
                                                hasSpan = true
                                            }
                                            
                                            
                                            str = str.trimmingCharacters(in: .whitespacesAndNewlines)
                                            str = str.replacingOccurrences(of: "<em>", with: "_").replacingOccurrences(of: "</em>", with: "_")
                                            
                                            str = str.stringByRemovingHTMLTags()
                                            
                                            var fontSize: Double = 16.0
                                            var margin: Margin = Margin()
                                            var align: Align = hasSpan ? .center : .leading
                                            
                                            if let cssString {
                                                if let parsedProperties = extractAndParseCSS(cssString: cssString, forSelector: ".\(try element.className())") {
                                                    for property in parsedProperties {
                                                        if property.name == "font-size" {
                                                            let multiplier = property.value.replacingOccurrences(of: "em", with: "")
                                                            
                                                            let size: Double = 16.0 * (Double(multiplier) ?? 1.0)
                                                            fontSize = size
                                                        } else if property.name.contains("margin") {
                                                            if property.name.contains("top") {
                                                                let multiplier = property.value.replacingOccurrences(of: "em", with: "")
                                                                
                                                                let size: Double = 16.0 * (Double(multiplier) ?? 1.0)
                                                                margin.top = size
                                                            } else if property.name.contains("bottom") {
                                                                let multiplier = property.value.replacingOccurrences(of: "em", with: "")
                                                                
                                                                let size: Double = 16.0 * (Double(multiplier) ?? 1.0)
                                                                margin.bottom = size
                                                            } else if property.name.contains("left") {
                                                                let multiplier = property.value.replacingOccurrences(of: "em", with: "")
                                                                
                                                                let size: Double = 16.0 * (Double(multiplier) ?? 1.0)
                                                                margin.left = size
                                                            } else if property.name.contains("right") {
                                                                let multiplier = property.value.replacingOccurrences(of: "em", with: "")
                                                                
                                                                let size: Double = 16.0 * (Double(multiplier) ?? 1.0)
                                                                margin.right = size
                                                            }
                                                        } else if property.name == "text-align" {
                                                            if property.value == "center" {
                                                                align = .center
                                                            } else if property.value == "start" {
                                                                align = .leading
                                                            } else if property.value == "end" {
                                                                align = .trailing
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                            
                                            
                                            let pTag = Tag(type: .p, value: str, fontSize: fontSize, margin: margin, align: align)
                                            list.append(pTag)
                                            continue
                                        }
                                    }
                                    
                                    let parsed = ParsedSpine(title: title ?? "", id: html.id, tags: list)
                                    parsedSpines.append(parsed)
                                }
                            } catch {
                                print("Error parsing HTML: \(error)")
                            }
                        }
                    }
                }
            } else {
                print("Parsing failed.")
            }
            
            // Perform further processing with the content of content.opf here
            
        } catch {
            print("Failed to unzip EPUB: \(error)")
            return
        }
    }

}
