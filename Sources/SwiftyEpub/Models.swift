//
//  File.swift
//  
//
//  Created by Inumaki on 14.11.23.
//

import Foundation

public struct Package {
    public var metadata: Metadata
    public var manifest: Manifest
    public var spine: Spine
    public var guide: Guide
}

public struct Metadata {
    public var title: String
    public var creator: String
    public var publisher: String
    public var date: String
    public var rights: String
    public var source: String
    public var identifier: String
    public var language: String
    public var description: String
    public var format: String
    // Add other metadata properties as needed
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
    public var toc: String
    public var items: [SpineItem]
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
}

public struct Margin {
    public var top: Double = 0.0
    public var bottom: Double = 0.0
    public var left: Double = 0.0
    public var right: Double = 0.0
}

public enum Align {
    case center
    case leading
    case trailing
}

public struct Tag {
    public var type: TagType
    public var value: String
    public var fontSize: Double = 16.0
    public var margin: Margin = Margin()
    public var align: Align = .leading
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
