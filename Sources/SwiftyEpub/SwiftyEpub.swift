// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import ZIPFoundation
import SwiftSoup
import WebKit
import UIKit
import AEXML

extension String {
    func stringByRemovingHTMLTags() -> String {
        return self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
    }
}

protocol LocalizedDescribable {
    var localizedDescription: String { get }
}

public enum EpubError: Error {
    case invalidPath
    case bookNotAvailable
}

extension EpubError: LocalizedDescribable {
    var localizedDescription: String {
        switch self {
            case .invalidPath:
                return NSLocalizedString("The provided path is invalid.", comment: "")
            case .bookNotAvailable:
                return NSLocalizedString("The book you selected is not available.", comment: "")
            // Provide localized descriptions for other cases
        }
    }
}


public struct SwiftyEpub {
    public var book: Book = Book()
    public var metadata: Metadata? = nil
    public var spine: Spine? = nil
    public var manifest: Manifest? = nil
    public var navElement: NavElement? = nil
    public var parsedSpines: [ParsedSpine] = []
    public var navItems: [NavItem] = []
    public var pageCount: Int = 0
    public var hiddenPageCount: Int = 0
    public var chapterPageCounts: [ChapterPageCount] = []
    
    var resourcesBasePath = ""
    
    
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
    
    func numberOfLines(for text: String, fontSize: Double, containerWidth: CGFloat) -> Int {
        let font = UIFont.systemFont(ofSize: CGFloat(fontSize))
        let textAttributes = [NSAttributedString.Key.font: font]
        let attributedText = NSAttributedString(string: text, attributes: textAttributes)
        
        let textRect = attributedText.boundingRect(with: CGSize(width: containerWidth, height: CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, context: nil)
        
        let numberOfLines = Int(ceil(textRect.size.height / font.lineHeight))
        
        return numberOfLines
    }
    
    
    func countEmptyLines(in htmlString: String) -> Int {
        let pattern = #"^\s*$"#
        let regex = try! NSRegularExpression(pattern: pattern, options: .anchorsMatchLines)
        let range = NSRange(htmlString.startIndex..<htmlString.endIndex, in: htmlString)
        
        let matches = regex.matches(in: htmlString, options: [], range: range)
        return matches.count
    }
    
    func calculateContentHeight(htmlString: String, cssString: String, completion: @escaping (CGFloat) -> Void) {
        DispatchQueue.main.async {
            let webView = WKWebView(frame: .zero)
            webView.translatesAutoresizingMaskIntoConstraints = false

            let htmlWithStyle = "<html><head><style>\(cssString)</style></head><body>\(htmlString)</body></html>"
            webView.loadHTMLString(htmlWithStyle, baseURL: nil)
            
            webView.scrollView.isScrollEnabled = false
            webView.scrollView.bounces = false

            UIApplication.shared.windows.first { $0.isKeyWindow }?.addSubview(webView)

            webView.evaluateJavaScript("document.readyState", completionHandler: { _, _ in
                webView.evaluateJavaScript("document.body.scrollHeight", completionHandler: { result, error in
                    if let height = result as? CGFloat {
                        DispatchQueue.main.async {
                            webView.removeFromSuperview()
                            completion(height)
                        }
                    } else {
                        DispatchQueue.main.async {
                            print("Failed to get content height: \(error?.localizedDescription ?? "Unknown error")")
                            webView.removeFromSuperview()
                            completion(0)
                        }
                    }
                })
            })
        }
    }
    
    
    public mutating func readEpub(epubPath withEpubPath: String) throws -> Book {
        guard let epubUrl = URL(string: withEpubPath) else { throw EpubError.invalidPath }
        
        let fileManager = FileManager.default
        let bookName = epubUrl.lastPathComponent.replacingOccurrences(of: ".epub", with: "")
        var bookBasePath: URL
        
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { throw EpubError.invalidPath }
        
        let basePath = documentsDirectory.appendingPathComponent("Epubs")

        bookBasePath = basePath.appendingPathComponent(bookName)

        guard fileManager.fileExists(atPath: withEpubPath.replacingOccurrences(of: "file://", with: "")) else {
            throw EpubError.bookNotAvailable
        }
        
        // Unzip if necessary
        if !fileManager.fileExists(atPath: bookBasePath.absoluteString.replacingOccurrences(of: "file://", with: "")) {
            try fileManager.unzipItem(at: epubUrl, to: bookBasePath)
        }
        
        book.name = bookName
        try parseContainer(with: bookBasePath.absoluteString)
        try parseOpf(with: bookBasePath.absoluteString)
        return self.book
    }
    
    public mutating func parseContainer(with bookBasePath: String) throws {
        guard let basePath = URL(string: bookBasePath) else { return }
        
        let containerPath = basePath.appendingPathComponent("META-INF/container.xml")
        let containerString = try String(contentsOf: containerPath, encoding: .utf8)
        
        var opfResource = EpubResource(id: "", properties: "", mediaType: MediaType.xhtml, href: "", fullHref: "")
        
        let pattern = "full-path=\"([^\"]*)\""
        let regex = try! NSRegularExpression(pattern: pattern, options: [])

        if let match = regex.firstMatch(in: containerString, options: [], range: NSRange(location: 0, length: containerString.utf16.count)) {
            let range = match.range(at: 1)
            if let swiftRange = Range(range, in: containerString) {
                let fullPath = containerString[swiftRange]
                
                opfResource.href = String(fullPath)
            }
        }
        guard let opfHref = URL(string: opfResource.href) else { return }
        
        book.opfResource = opfResource
        resourcesBasePath = basePath.appendingPathComponent(opfHref.deletingLastPathComponent().absoluteString).absoluteString
    }
    
    public mutating func parseOpf(with bookBasePath: String) throws {
        guard let basePath = URL(string: bookBasePath) else { return }
        
        let fileManager = FileManager.default
        let opfUrl = basePath.appendingPathComponent(book.opfResource.href)
        
        // Read the contents of the content.opf file as a string
        let opfData = try String(contentsOf: opfUrl, encoding: .utf8)
        let xmlDoc = try AEXMLDocument(xml: opfData)
        
        var identifier: String?
        
        // Base OPF info
        if let package = xmlDoc.children.first {
            identifier = package.attributes["unique-identifier"]

            if let version = package.attributes["version"] {
                book.version = Double(version) ?? 3.0
            }
        }
        
        // Parse and save each "manifest item"
        xmlDoc.root["manifest"]["item"].all?.forEach {
            guard let basePath = URL(string: resourcesBasePath) else { return }
            
            var resource = EpubResource(id: "", properties: "", mediaType: MediaType.xhtml, href: "", fullHref: "")
            resource.id = $0.attributes["id"] ?? ""
            resource.properties = $0.attributes["properties"] ?? ""
            resource.href = $0.attributes["href"] ?? ""
            resource.fullHref = basePath.appendingPathComponent(resource.href).absoluteString.removingPercentEncoding ?? ""
            resource.mediaType = MediaType.by(name: $0.attributes["media-type"] ?? "", fileName: resource.href)
            

            book.manifest.append(resource)
        }
        
        // Read metadata
        book.metadata = readMetadata(xmlDoc.root["metadata"].children)
        
        // Read the cover image
        let coverImageId = book.metadata?.find(byName: "cover")?.content
        if let coverImageId = coverImageId, let coverResource = findById(coverImageId, book.manifest) {
            book.coverImage = coverResource
            
            // save the cover for easy access
            let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            
            if documentsDirectory != nil {
                let basePath = documentsDirectory!.appendingPathComponent("Epubs")
                
                if let atUrl = URL(string: coverResource.fullHref) {
                    if !fileManager.fileExists(atPath: basePath.appendingPathComponent(book.name).appendingPathComponent("cover.jpg").absoluteString.replacingOccurrences(of: "file://", with: "")) {
                        try fileManager.copyItem(at: atUrl, to: basePath.appendingPathComponent(book.name).appendingPathComponent("cover.jpg"))
                    }
                }
            }
        } else if let coverResource = findByProperty("cover-image", book.manifest) {
            book.coverImage = coverResource
            
            // save the cover for easy access
            let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            
            if documentsDirectory != nil {
                let basePath = documentsDirectory!.appendingPathComponent("Epubs")
                
                if let atUrl = URL(string: coverResource.fullHref) {
                    if !fileManager.fileExists(atPath: basePath.appendingPathComponent(book.name).appendingPathComponent("cover.jpg").absoluteString.replacingOccurrences(of: "file://", with: "")) {
                        try fileManager.copyItem(at: atUrl, to: basePath.appendingPathComponent(book.name).appendingPathComponent("cover.jpg"))
                    }
                }
            }
        }
        
        if let coverHref = book.coverImage?.fullHref {
            let imageData = try Data(contentsOf: URL(string: coverHref)!)
            if let loadedImage = UIImage(data: imageData) {
                if let data = loadedImage.jpegData(compressionQuality: 1.0) {
                    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                    let coversDirectory = documentsDirectory.appendingPathComponent("Covers")
                    
                    do {
                        try FileManager.default.createDirectory(at: coversDirectory, withIntermediateDirectories: true, attributes: nil)
                        
                        let fileURL = coversDirectory.appendingPathComponent("\(book.name).jpg")
                        try data.write(to: fileURL)
                    } catch {
                        print("Error saving image: \(error.localizedDescription)")
                    }
                }
            }
        }
        
        // Specific TOC for ePub 2 and 3
        // Get the first resource with the NCX mediatype
        if let tocResource = findByMediaType(MediaType.ncx, book.manifest) {
            book.tocResource = tocResource
        } else if let tocResource = findByExtension(MediaType.ncx.defaultExtension, book.manifest) {
            // Non-standard books may use wrong mediatype, fallback with extension
            book.tocResource = tocResource
        } else if let tocResource = findByProperty("nav", book.manifest) {
            book.tocResource = tocResource
        }
        
        // The book TOC
        book.tableOfContents = findTableOfContents()
        //book.flatTableOfContents = flatTOC
        
        // Read Spine
        let spine = xmlDoc.root["spine"]
        book.spine = readSpine(spine.children)
        
        // Store css
        let cssPath = book.manifest.filter { element in
            element.id.contains("style")
        }.first
        
        if let cssPath {
            let cssURL = opfUrl.deletingLastPathComponent().appendingPathComponent(cssPath.href)
           
            print(cssURL.absoluteString.replacingOccurrences(of: "file://", with: ""))
            
            book.cssString = try String(contentsOfFile: cssURL.absoluteString.replacingOccurrences(of: "file://", with: ""), encoding: .utf8)
        }
    }
    
    public func parseChapter(_ resource: EpubResource) throws -> [HTMLComponent] {
        guard let basePath = URL(string: resourcesBasePath) else { return [] }
        
        let htmlContent = try String(contentsOfFile: basePath.appendingPathComponent(resource.href).absoluteString.replacingOccurrences(of: "file://", with: ""), encoding: .utf8)
        
        var list: [HTMLComponent] = []
        
        do {
            let doc: Document = try SwiftSoup.parse(htmlContent)
            if let elements = try doc.body()?.select("body > *") {
                list = try parseHTMLRecursive(elements)
            }
        } catch {
            print("Error parsing HTML: \(error)")
        }
        
        return list
    }
    
    // try element.className()
    
    // Helper function to parse CSS properties
    func parseCSSProperties(cssString: String, forSelector selector: String, completion: @escaping (CSSProperties) -> Void) {
        var cssProperties = CSSProperties()
        
        if let parsedProperties = extractAndParseCSS(cssString: book.cssString, forSelector: ".\(selector)") {
            for property in parsedProperties {
                if property.name == "font-size" {
                    let multiplier = property.value.replacingOccurrences(of: "em", with: "")
                    
                    let size: Double = 16.0 * (Double(multiplier) ?? 1.0)
                    cssProperties.fontSize = size
                } else if property.name.contains("margin") {
                    if property.name.contains("top") {
                        let multiplier = property.value.replacingOccurrences(of: "em", with: "")
                        
                        let size: Double = 16.0 * (Double(multiplier) ?? 1.0)
                        cssProperties.margin.top = size
                    } else if property.name.contains("bottom") {
                        let multiplier = property.value.replacingOccurrences(of: "em", with: "")
                        
                        let size: Double = 16.0 * (Double(multiplier) ?? 1.0)
                        cssProperties.margin.bottom = size
                    } else if property.name.contains("left") {
                        let multiplier = property.value.replacingOccurrences(of: "em", with: "")
                        
                        let size: Double = 16.0 * (Double(multiplier) ?? 1.0)
                        cssProperties.margin.left = size
                    } else if property.name.contains("right") {
                        let multiplier = property.value.replacingOccurrences(of: "em", with: "")
                        
                        let size: Double = 16.0 * (Double(multiplier) ?? 1.0)
                        cssProperties.margin.right = size
                    }
                } else if property.name == "text-align" {
                    if property.value == "center" {
                        cssProperties.align = Align.center
                    } else if property.value == "start" {
                        cssProperties.align = Align.leading
                    } else if property.value == "end" {
                        cssProperties.align = Align.trailing
                    }
                }
                //print("Property Name: \(property.name), Value: \(property.value)")
            }
        }
        
        completion(cssProperties)
    }
    
    func splitInnerHTML(_ innerHTML: String) -> [String] {
        var result = [String]()
        
        let pattern = #"<[^>]+>.*?<\/[^>]+>|<[^>]+>|[^<]+"#
        
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let matches = regex.matches(in: innerHTML, options: [], range: NSRange(location: 0, length: innerHTML.utf16.count))
        
        for match in matches {
            if let range = Range(match.range, in: innerHTML) {
                let substring = String(innerHTML[range])
                result.append(substring)
            }
        }
        
        return result
    }


    
    func convertToElement(_ htmlString: String) -> Element? {
        do {
            let doc: Document = try SwiftSoup.parse(htmlString)
            return try doc.select("body > *").first()
        } catch Exception.Error(let type, let message) {
            print(type, message)
        } catch {
            print("Error parsing the HTML string")
        }
        return nil
    }
    
    // Helper function to parse an HTML tag with its children
    func parseHTMLTag(_ element: Element, book: Book) throws -> HTMLComponent {
        
        if element.tagName() == "h2" {
            var fontSize: Double = 22.0
            var margin: Margin = Margin()
            var align: Align = .center
            
            if !book.cssString.isEmpty {
                parseCSSProperties(cssString: book.cssString, forSelector: try element.className()) { props in
                    fontSize = props.fontSize
                    margin = props.margin
                    align = props.align
                }
            }
            
            let style = try element.attr("style")
            
            if !style.isEmpty {
                parseCSSProperties(cssString: style, forSelector: try element.className()) { props in
                    fontSize = props.fontSize
                    margin = props.margin
                    align = props.align
                }
            }
            
            let text = try element.text()
            
            return .tag(.h2(text: text))
        }
        
        if element.tagName() == "h3" {
            var fontSize: Double = 20.0
            var margin: Margin = Margin()
            var align: Align = .center
            
            if !book.cssString.isEmpty {
                parseCSSProperties(cssString: book.cssString, forSelector: try element.className()) { props in
                    fontSize = props.fontSize
                    margin = props.margin
                    align = props.align
                }
            }
            
            let style = try element.attr("style")
            
            if !style.isEmpty {
                parseCSSProperties(cssString: style, forSelector: try element.className()) { props in
                    fontSize = props.fontSize
                    margin = props.margin
                    align = props.align
                }
            }
            
            let text = try element.text()
            
            return .tag(.h3(text: text))
        }
        
        if element.tagName() == "div" {
            var contentList: [HTMLComponent] = []
            let childNodes = element.childNodesCopy()
            
            for childNode in childNodes {
                if let textNode = childNode as? TextNode {
                    let text = textNode.text()
                    contentList.append(.text(text))
                } else if let elementNode = childNode as? Element {
                    let element = try parseHTMLTag(elementNode, book: book)
                    contentList.append(element)
                }
            }
            return .tag(.div(content: contentList, padding: nil))
        }
        
        if element.tagName() == "ul" {
            
            var contentList: [HTMLComponent] = []
            
            let children = element.children()
            for child in children {
                let el = try parseHTMLTag(child, book: self.book)
                contentList.append(el)
            }
            
            return .tag(.ul(items: contentList))
        }
        
        if element.tagName() == "ol" {
            
            var contentList: [HTMLComponent] = []
            
            let children = element.children()
            for child in children {
                let el = try parseHTMLTag(child, book: self.book)
                contentList.append(el)
            }
            
            return .tag(.ol(items: contentList))
        }
        
        if element.tagName() == "fieldset" {
            
            var contentList: [HTMLComponent] = []
            
            let children = element.children()
            for child in children {
                let el = try parseHTMLTag(child, book: self.book)
                contentList.append(el)
            }
            
            return .tag(.fieldset(content: contentList))
        }
        
        if element.tagName() == "h4" {
            var fontSize: Double = 14.0
            var margin: Margin = Margin()
            var align: Align = .leading
            
            if !book.cssString.isEmpty {
                parseCSSProperties(cssString: book.cssString, forSelector: try element.className()) { props in
                    fontSize = props.fontSize
                    margin = props.margin
                    align = props.align
                }
            }
            
            var str = try element.html()
            
            str = str.trimmingCharacters(in: .whitespacesAndNewlines)
            str = str.replacingOccurrences(of: "<br/>", with: "\n").replacingOccurrences(of: "<em>", with: "_").replacingOccurrences(of: "</em>", with: "_")

            return .tag(.h4(text: str))
        }
        
        if element.tagName() == "h1" {
            var fontSize: Double = 14.0
            var margin: Margin = Margin()
            var align: Align = .leading
            
            if !book.cssString.isEmpty {
                parseCSSProperties(cssString: book.cssString, forSelector: try element.className()) { props in
                    fontSize = props.fontSize
                    margin = props.margin
                    align = props.align
                }
            }
            
            var str = try element.html()
            
            str = str.trimmingCharacters(in: .whitespacesAndNewlines)
            str = str.replacingOccurrences(of: "<br/>", with: "\n").replacingOccurrences(of: "<em>", with: "_").replacingOccurrences(of: "</em>", with: "_")

            return .tag(.h1(text: str))
        }
        
        if element.tagName() == "nav" || element.tagName() == "section" || element.tagName() == "figure" {
            var contentList: [HTMLComponent] = []
            
            let children = element.children()
            for child in children {
                let el = try parseHTMLTag(child, book: self.book)
                contentList.append(el)
            }
            
            return .tag(.div(content: contentList, padding: nil))
        }
        
        if element.tagName() == "li" {
            if try element.html().contains("</a>") {
                return .tag(.a(text: try element.text(), url: ""))
            }
            return .tag(.li(text: try element.text()))
        }
        
        if element.tagName() == "a" {
            return .tag(.a(text: try element.text(), url: ""))
        }
        
        if element.tagName() == "p" {
            var str = try element.html()
            
            return .tag(.p(content: [.text(str)]))
            
            str = str.trimmingCharacters(in: .whitespacesAndNewlines)
            
            var fontSize: Double = 16.0
            var margin: Margin = Margin()
            var align: Align = .leading
            
            if !book.cssString.isEmpty {
                parseCSSProperties(cssString: book.cssString, forSelector: try element.className()) { props in
                    fontSize = props.fontSize
                    margin = props.margin
                    align = props.align
                }
            }
            
            let splitContent = splitInnerHTML(str)
            
            var contentList: [HTMLComponent] = []
            
            for sub in splitContent {
                if let elem = convertToElement(sub) {
                    let t = try parseHTMLTag(elem, book: self.book)
                    contentList.append(t)
                } else {
                    contentList.append(HTMLComponent.text(sub))
                }
            }
            return .tag(.p(content: contentList))
//            return .tag(.p(content: [.text(str, .regular, fontSize)]))
        }
        
        if element.tagName() == "span" {
            var str = try element.html()
            
            str = str.trimmingCharacters(in: .whitespacesAndNewlines)
            
            var fontSize: Double = 16.0
            var margin: Margin = Margin()
            var align: Align = .leading
            
            if !book.cssString.isEmpty {
                parseCSSProperties(cssString: book.cssString, forSelector: try element.className()) { props in
                    fontSize = props.fontSize
                    margin = props.margin
                    align = props.align
                }
            }
            
            let splitContent = splitInnerHTML(str)
            
            var contentList: [HTMLComponent] = []
            
            for sub in splitContent {
                if let elem = convertToElement(sub) {
                    let t = try parseHTMLTag(elem, book: self.book)
                    contentList.append(t)
                } else {
                    contentList.append(HTMLComponent.text(sub))
                }
            }
            return .tag(.span(content: contentList, style: nil))
//            return .tag(.p(content: [.text(str, .regular, fontSize)]))
        }
        
        if element.tagName() == "br" {
            return .tag(.br)
        }
        
        if element.tagName() == "img" {
            let src = try element.attr("src").replacingOccurrences(of: "../", with: "")
            if let basePath = URL(string: resourcesBasePath) {
                
                let imgPath = basePath.appendingPathComponent(src)
                
                if let image = UIImage(contentsOfFile: imgPath.absoluteString.replacingOccurrences(of: "file://", with: "")) {
                    let originalWidth = image.size.width
                    let originalHeight = image.size.height
                    
                    let givenWidth = UIScreen.main.bounds.width - 40
                    
                    let aspectRatio = originalHeight / originalWidth
                    let calculatedHeight = givenWidth * aspectRatio
                    
                } else {
                    print("Image couldn't be loaded.")
                }
                
                return .tag(.img(url: imgPath.absoluteString))
            }
        }
        
        return .text("")
    }
    
    // Recursive function to parse HTML elements and their children
    func parseHTMLRecursive(_ elements: Elements) throws -> [HTMLComponent] {
        var tags: [HTMLComponent] = []
        
        for element in elements {
            var tag = try parseHTMLTag(element, book: book)
            let childrenElements = element.children()
            let childrenTags = try parseHTMLRecursive(childrenElements)
            if case var .tag(t) = tag {
                if case var .p(content) = t {
                    content += childrenTags
                }
            }
            tags.append(tag)
        }
        
        return tags
    }
    
    /// Read and parse <spine>.
    ///
    /// - Parameter tags: XHTML tags
    /// - Returns: Spine object
    fileprivate func readSpine(_ tags: [AEXMLElement]) -> Spine {
        var spine = Spine()

        for tag in tags {
            guard let idref = tag.attributes["idref"] else { continue }
            var linear = true

            if tag.attributes["linear"] != nil {
                linear = tag.attributes["linear"] == "yes" ? true : false
            }

            if containsById(idref,  book.manifest) {
                guard let resource = findById(idref, book.manifest) else { continue }
                spine.spineReferences.append(SpineReference(resource: resource, linear: linear))
            }
        }
        return spine
    }
    
    /// Read and parse the Table of Contents.
    ///
    /// - Returns: A list of toc references
    private func findTableOfContents() -> [TocReference] {
        var tableOfContent = [TocReference]()
        var tocItems: [AEXMLElement]?
        guard let tocResource = book.tocResource else { return tableOfContent }
        guard let basePath = URL(string: resourcesBasePath) else { return tableOfContent }
        let tocPath = basePath.appendingPathComponent(tocResource.href)

        do {
            if tocResource.mediaType == MediaType.ncx {
                let ncxData = try Data(contentsOf: tocPath, options: .alwaysMapped)
                let xmlDoc = try AEXMLDocument(xml: ncxData)
                if let itemsList = xmlDoc.root["navMap"]["navPoint"].all {
                    tocItems = itemsList
                }
            } else {
                let tocData = try Data(contentsOf: tocPath, options: .alwaysMapped)
                let xmlDoc = try AEXMLDocument(xml: tocData)

                if let nav = xmlDoc.root["body"]["nav"].first, let itemsList = nav["ol"]["li"].all {
                    tocItems = itemsList
                } else if let nav = findNavTag(xmlDoc.root["body"]), let itemsList = nav["ol"]["li"].all {
                    tocItems = itemsList
                }
            }
        } catch {
            print("Cannot find Table of Contents.")
        }

        guard let items = tocItems else { return tableOfContent }

        for item in items {
            guard let ref = readTOCReference(item) else { continue }
            tableOfContent.append(ref)
        }

        return tableOfContent
    }
    
    /// Recursively finds a `<nav>` tag on html.
    ///
    /// - Parameter element: An `AEXMLElement`, usually the `<body>`
    /// - Returns: If found the `<nav>` `AEXMLElement`
    @discardableResult func findNavTag(_ element: AEXMLElement) -> AEXMLElement? {
        for element in element.children {
            if let nav = element["nav"].first {
                return nav
            } else {
                findNavTag(element)
            }
        }
        return nil
    }
    
    /// Read and parse <metadata>.
    ///
    /// - Parameter tags: XHTML tags
    /// - Returns: Metadata object
    fileprivate func readMetadata(_ tags: [AEXMLElement]) -> Metadata {
        var metadata = Metadata()

        for tag in tags {
            if tag.name == "dc:title" {
                metadata.titles.append(tag.value ?? "")
            }

            if tag.name == "dc:identifier" {
                let identifier = Identifier(id: tag.attributes["id"], scheme: tag.attributes["opf:scheme"], value: tag.value)
                metadata.identifiers.append(identifier)
            }

            if tag.name == "dc:language" {
                let language = tag.value ?? metadata.language
                metadata.language = language != "en" ? language : metadata.language
            }

            if tag.name == "dc:creator" {
                metadata.creators.append(Author(name: tag.value ?? "", role: tag.attributes["opf:role"] ?? "", fileAs: tag.attributes["opf:file-as"] ?? ""))
            }

            if tag.name == "dc:contributor" {
                metadata.creators.append(Author(name: tag.value ?? "", role: tag.attributes["opf:role"] ?? "", fileAs: tag.attributes["opf:file-as"] ?? ""))
            }

            if tag.name == "dc:publisher" {
                metadata.publishers.append(tag.value ?? "")
            }

            if tag.name == "dc:description" {
                metadata.descriptions.append(tag.value ?? "")
            }

            if tag.name == "dc:subject" {
                metadata.subjects.append(tag.value ?? "")
            }

            if tag.name == "dc:rights" {
                metadata.rights.append(tag.value ?? "")
            }

            if tag.name == "dc:date" {
                metadata.dates.append(EventDate(date: tag.value ?? "", event: tag.attributes["opf:event"] ?? ""))
            }

            if tag.name == "meta" {
                if tag.attributes["name"] != nil {
                    metadata.metaAttributes.append(Meta(name: tag.attributes["name"], content: tag.attributes["content"]))
                }

                if tag.attributes["property"] != nil && tag.attributes["id"] != nil {
                    metadata.metaAttributes.append(Meta(id: tag.attributes["id"], property: tag.attributes["property"], value: tag.value))
                }

                if tag.attributes["property"] != nil {
                    metadata.metaAttributes.append(Meta(property: tag.attributes["property"], value: tag.value, refines: tag.attributes["refines"]))
                }
            }
        }
        return metadata
    }
    
    /**
     Gets the resource with the given href.
     */
    fileprivate func findById(_ id: String?, _ resources: [EpubResource]) -> EpubResource? {
        guard let id = id else { return nil }

        for resource in resources {
            if resource.id == id {
                return resource
            }
        }
        return nil
    }
    
    fileprivate func findByProperty(_ properties: String, _ resources: [EpubResource]) -> EpubResource? {
        for resource in resources {
            if resource.properties == properties {
                return resource
            }
        }
        return nil
    }
    
    fileprivate func findByMediaType(_ mediaType: MediaType, _ resources: [EpubResource]) -> EpubResource? {
        for resource in resources {
            if resource.mediaType == mediaType {
                return resource
            }
        }
        return nil
    }
    
    fileprivate func findByExtension(_ ext: String, _ resources: [EpubResource]) -> EpubResource? {
        for resource in resources {
            if resource.mediaType.defaultExtension == ext {
                return resource
            }
        }
        return nil
    }
    
    fileprivate func findByHref(_ href: String, _ resources: [EpubResource]) -> EpubResource? {
        guard !href.isEmpty else { return nil }

        // This clean is neede because may the toc.ncx is not located in the root directory
        let cleanHref = href.replacingOccurrences(of: "../", with: "")
        return resources.first { res in
            res.href == cleanHref
        }
    }
    
    fileprivate func containsById(_ id: String?, _ resources: [EpubResource]) -> Bool {
        guard let id = id else { return false }

        for resource in resources {
            if resource.id == id {
                return true
            }
        }
        return false
    }
    
    fileprivate func readTOCReference(_ navpointElement: AEXMLElement) -> TocReference? {
        var label = ""

        if book.tocResource?.mediaType == MediaType.ncx {
            if let labelText = navpointElement["navLabel"]["text"].value {
                label = labelText
            }

            guard let reference = navpointElement["content"].attributes["src"] else { return nil }
            let hrefSplit = reference.split {$0 == "#"}.map { String($0) }
            let fragmentID = hrefSplit.count > 1 ? hrefSplit[1] : ""
            let href = hrefSplit[0]

            let resource = findByHref(href, book.manifest)
            var toc = TocReference(title: label, resource: resource, fragmentID: fragmentID, children: [])

            // Recursively find child
            if let navPoints = navpointElement["navPoint"].all {
                for navPoint in navPoints {
                    guard let item = readTOCReference(navPoint) else { continue }
                    toc.children.append(item)
                }
            }
            return toc
        } else {
            if let labelText = navpointElement["a"].value {
                label = labelText
            }

            guard let reference = navpointElement["a"].attributes["href"] else { return nil }
            let hrefSplit = reference.split {$0 == "#"}.map { String($0) }
            let fragmentID = hrefSplit.count > 1 ? hrefSplit[1] : ""
            let href = hrefSplit[0]

            let resource = findByHref(href, book.manifest)
            var toc = TocReference(title: label, resource: resource, fragmentID: fragmentID, children: [])

            // Recursively find child
            if let navPoints = navpointElement["ol"]["li"].all {
                for navPoint in navPoints {
                    guard let item = readTOCReference(navPoint) else { continue }
                    toc.children.append(item)
                }
            }
            return toc
        }
    }
}
