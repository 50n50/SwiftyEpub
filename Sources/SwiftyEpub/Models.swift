//
//  File.swift
//  
//
//  Created by Inumaki on 14.11.23.
//

import Foundation
import SwiftUI

public struct Book {
    public var opfResource: EpubResource = EpubResource(id: "", properties: "", mediaType: MediaType.xhtml, href: "", fullHref: "")
    public var tocResource: EpubResource? = nil
    
    public var name: String = ""
    public var version: Double = 3.0
    public var uniqueIdentifier: String = ""
    
    public var manifest: [EpubResource] = []
    public var metadata: Metadata? = nil
    public var spine: Spine? = nil
    
    public var coverImage: EpubResource? = nil
    
    public var cssString: String = ""
    
    public var tableOfContents: [TocReference] = []
}

public struct EpubResource {
    public var id: String
    public var properties: String
    public var mediaType: MediaType
    
    public var href: String
    public var fullHref: String
    
    func basePath() -> String {
        if href.isEmpty { return "" }
        var paths = fullHref.components(separatedBy: "/")
        paths.removeLast()
        return paths.joined(separator: "/")
    }
}

public struct TocReference {
    public var title: String = ""
    public var resource: EpubResource? = nil
    public var fragmentID: String? = nil
    
    public var children: [TocReference]
    
    public init(title: String, resource: EpubResource?, fragmentID: String, children: [TocReference]) {
        self.resource = resource
        self.title = title
        self.fragmentID = fragmentID
        self.children = children
    }
}

public struct NavElement {
    public var href: String
}

public struct ChapterPageCount {
    public var chapterName: String
    public var count: Double
}

public struct NavItem {
    public var href: String
    public var id: String
    public var text: String
}

public struct Author {
    public var name: String
    public var role: String
    public var fileAs: String

    public init(name: String, role: String, fileAs: String) {
        self.name = name
        self.role = role
        self.fileAs = fileAs
    }
}

public struct Identifier {
    public var id: String?
    public var scheme: String?
    public var value: String?

    public init(id: String?, scheme: String?, value: String?) {
        self.id = id
        self.scheme = scheme
        self.value = value
    }
}

public struct EventDate {
    public var date: String
    public var event: String?

    public init(date: String, event: String?) {
        self.date = date
        self.event = event
    }
}

public struct Meta {
    public var name: String?
    public var content: String?
    public var id: String?
    public var property: String?
    public var value: String?
    public var refines: String?

    public init(name: String? = nil, content: String? = nil, id: String? = nil, property: String? = nil,
         value: String? = nil, refines: String? = nil) {
        self.name = name
        self.content = content
        self.id = id
        self.property = property
        self.value = value
        self.property = property
        self.value = value
        self.refines = refines
    }
}

public struct Metadata {
    public var creators = [Author]()
    public var contributors = [Author]()
    public var dates = [EventDate]()
    public var language = "en-US"
    public var titles = [String]()
    public var identifiers = [Identifier]()
    public var subjects = [String]()
    public var descriptions = [String]()
    public var publishers = [String]()
    public var format = MediaType.epub.name
    public var rights = [String]()
    public var metaAttributes = [Meta]()
    // Add other metadata properties as needed
    
    /**
     Find a book unique identifier by ID

     - parameter id: The ID
     - returns: The unique identifier of a book
     */
    func find(identifierById id: String) -> Identifier? {
        return identifiers.filter({ $0.id == id }).first
    }

    func find(byName name: String) -> Meta? {
        return metaAttributes.filter({ $0.name == name }).first
    }

    func find(byProperty property: String, refinedBy: String? = nil) -> Meta? {
        return metaAttributes.filter {
            if let refinedBy = refinedBy {
                return $0.property == property && $0.refines == refinedBy
            }
            return $0.property == property
        }.first
    }
}

public struct ManifestItem {
    public var href: String
    public var id: String
    public var mediaType: String
    public var properties: String?
}

public struct Manifest {
    public var items: [ManifestItem]
}

public struct SpineItem {
    public var idRef: String
    public var linear: String
}

public struct Spine {
    public var spineReferences: [SpineReference] = []
    
    public func nextChapter(_ href: String) -> EpubResource? {
        var found = false
        
        for item in spineReferences {
            if found {
                return item.resource
            }
            
            if item.resource.href == href {
                found = true
            }
        }
        
        return nil
    }
}

public struct SpineReference {
    public var linear: Bool
    public var resource: EpubResource
    
    public init(resource: EpubResource, linear: Bool = true) {
        self.linear = linear
        self.resource = resource
    }
}

public struct GuideReference {
    public var href: String
    public var title: String
    public var type: String
}

public struct Guide {
    public var references: [GuideReference]
}

public enum TagType {
    case h2
    case p
    case li
    case img
    case nl
    case h4
    case span
    case a
    
    case unknown
}

public struct Margin {
    public var top: Double = 0.0
    public var bottom: Double = 0.0
    public var left: Double = 0.0
    public var right: Double = 0.0
    
    public init(top: Double = 0.0, bottom: Double = 0.0, left: Double = 0.0, right: Double = 0.0) {
        self.top = top
        self.bottom = bottom
        self.left = left
        self.right = right
    }
}

public enum Align {
    case center
    case leading
    case trailing
}

public struct Tag {
    public var type: TagType
    public var value: String
    public var fontSize: Double?
    public var fontWeight: Font.Weight?
    public var margin: Margin?
    public var align: Align?
    public var children: [Tag] = []
    
    public init(type: TagType, value: String, fontSize: Double? = nil, fontWeight: Font.Weight? = nil, margin: Margin? = nil, align: Align? = nil, children: [Tag] = []) {
        self.type = type
        self.value = value
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.margin = margin
        self.align = align
        self.children = children
    }
}

public struct PassDownProps {
    public var fontSize: Double?
    public var fontWeight: Font.Weight?
    public var margin: Margin?
    public var align: Align?
    
    public init(fontSize: Double? = nil, fontWeight: Font.Weight? = nil, margin: Margin? = nil, align: Align? = nil) {
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.margin = margin
        self.align = align
    }
}


extension Tag {
    static public let COTE_Test = Tag(
        type: .p,
        value: "",
        align: .center,
        children: [
            Tag(
                type: .span,
                value: "",
                fontSize: 18.72,
                fontWeight: .bold,
                children: [
                    Tag(
                        type: .span,
                        value: "",
                        children: [
                            Tag(
                                type: .span,
                                value: "Chapter 1:",
                                children: []
                            ),
                            Tag(
                                type: .nl,
                                value: "",
                                children: []
                            ),
                            Tag(
                                type: .span,
                                value: "The Structure of",
                                children: []
                            ),
                            Tag(
                                type: .nl,
                                value: "",
                                children: [
                                    
                                ]
                            ),
                            Tag(
                                type: .span,
                                value: "Japanese Society",
                                children: []
                            )
                        ]
                    )
                ]
            )
        ]
    )
    
    static public let COTE_Text_2 = Tag(
        type: .p,
        value: "",
        children: [
            Tag(
                type: .span,
                value: "",
                fontSize: 48,
                fontWeight: .bold,
                children: [
                    Tag(
                        type: .span,
                        value: "I"
                    )
                ]
            ),
            Tag(
                type: .span,
                value: " ",
                fontSize: 16,
                fontWeight: .bold
            ),
            Tag(
                type: .span,
                value: "",
                fontSize: 16,
                children: [
                    Tag(
                        type: .span,
                        value: "know this is kind of sudden, but, please, it will only take a moment. "
                    ),
                    Tag(
                        type: .span,
                        value: "I want your honest opinion. "
                    )
                ]
            )
        ]
    )
}


public struct ParsedSpine {
    public var title: String
    public var id: String
    public var tags: [Tag]
}

// Define a struct to hold CSS properties
struct CSSProperty {
    let name: String
    let value: String
}

// Structure to hold CSS properties
public struct CSSProperties {
    public var fontSize: Double = 16.0
    public var margin: Margin = Margin()
    public var align: Align = .leading
    
    public init(fontSize: Double = 16.0, margin: Margin = Margin(), align: Align = .leading) {
        self.fontSize = fontSize
        self.margin = margin
        self.align = align
    }
    // Add more CSS properties as needed
}


public struct MediaType: Equatable {
    public let name: String
    public let defaultExtension: String
    public let extensions: [String]

    public init(name: String, defaultExtension: String, extensions: [String] = []) {
        self.name = name
        self.defaultExtension = defaultExtension
        self.extensions = extensions
    }
}

public struct Page {
    public let title: String
    public let number: Int
    public let data: [Tag]
    
    public init(title: String, number: Int, data: [Tag]) {
        self.title = title
        self.number = number
        self.data = data
    }
}

extension MediaType {
    static let xhtml = MediaType(name: "application/xhtml+xml", defaultExtension: "xhtml", extensions: ["htm", "html", "xhtml", "xml"])
    static let epub = MediaType(name: "application/epub+zip", defaultExtension: "epub")
    static let ncx = MediaType(name: "application/x-dtbncx+xml", defaultExtension: "ncx")
    static let opf = MediaType(name: "application/oebps-package+xml", defaultExtension: "opf")
    static let javaScript = MediaType(name: "text/javascript", defaultExtension: "js")
    static let css = MediaType(name: "text/css", defaultExtension: "css")

    // images
    static let jpg = MediaType(name: "image/jpeg", defaultExtension: "jpg", extensions: ["jpg", "jpeg"])
    static let png = MediaType(name: "image/png", defaultExtension: "png")
    static let gif = MediaType(name: "image/gif", defaultExtension: "gif")
    static let svg = MediaType(name: "image/svg+xml", defaultExtension: "svg")

    // fonts
    static let ttf = MediaType(name: "application/x-font-ttf", defaultExtension: "ttf")
    static let ttf1 = MediaType(name: "application/x-font-truetype", defaultExtension: "ttf")
    static let ttf2 = MediaType(name: "application/x-truetype-font", defaultExtension: "ttf")
    static let openType = MediaType(name: "application/vnd.ms-opentype", defaultExtension: "otf")
    static let woff = MediaType(name: "application/font-woff", defaultExtension: "woff")

    // audio
    static let mp3 = MediaType(name: "audio/mpeg", defaultExtension: "mp3")
    static let mp4 = MediaType(name: "audio/mp4", defaultExtension: "mp4")
    static let ogg = MediaType(name: "audio/ogg", defaultExtension: "ogg")

    static let smil = MediaType(name: "application/smil+xml", defaultExtension: "smil")
    static let xpgt = MediaType(name: "application/adobe-page-template+xml", defaultExtension: "xpgt")
    static let pls = MediaType(name: "application/pls+xml", defaultExtension: "pls")

    static let mediatypes = [xhtml, epub, ncx, opf, jpg, png, gif, javaScript, css, svg, ttf, ttf1, ttf2, openType, woff, mp3, mp4, ogg, smil, xpgt, pls]

    /**
     Gets the MediaType based on the file mimetype.
     - parameter name:     The mediaType name
     - parameter fileName: The file name to extract the extension
     - returns: A know mediatype or create a new one.
     */
    static func by(name: String, fileName: String?) -> MediaType {
        for mediatype in mediatypes {
            if mediatype.name == name {
                return mediatype
            }
        }
        let ext = (fileName as? NSString)?.pathExtension ?? ""
        return MediaType(name: name, defaultExtension: ext)
    }

    /**
     Gets the MediaType based on the file extension.
     */
    static func by(fileName: String) -> MediaType? {
        let ext = "." + (fileName as NSString).pathExtension
        return mediatypes.filter({ $0.extensions.contains(ext) }).first
    }

    /**
     Compare if the resource is a image.
     - returns: `true` if is a image and `false` if not
     */
    static func isBitmapImage(_ mediaType: MediaType) -> Bool {
        return mediaType == jpg || mediaType == png || mediaType == gif
    }

    /**
     Gets the MediaType based on the file extension.
     */
    static func determineMediaType(_ fileName: String) -> MediaType? {
        let ext = (fileName as NSString).pathExtension

        for mediatype in mediatypes {
            if mediatype.defaultExtension == ext {
                return mediatype
            }
            if mediatype.extensions.contains(ext) {
                return mediatype
            }
        }
        return nil
    }
}
