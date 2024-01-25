//
//  File.swift
//  
//
//  Created by Inumaki on 05.01.24.
//

import Foundation
import SwiftUI

extension Font {
    static func charterFont(weight: Font.Weight, size: CGFloat) -> Font {
        guard let charterFont = UIFont(name: "Iowan Old Style", size: size) else {
            fatalError("Charter font not found")
        }
        let font = Font(charterFont)
        return font.weight(weight)
    }
}

public enum TextType: String {
    case h1
    case h2
    case h3
    case h4
    case h5
    case h6
    case italic
    case bold
    case small
    case li
    
    public var font: Font {
        switch self {
        case .h1:
            return .charterFont(weight: .bold, size: 32)
        case .h2:
            return .charterFont(weight: .bold, size: 24)
        case .h3:
            return .charterFont(weight: .bold, size: 18)
        case .h4:
            return .charterFont(weight: .bold, size: 16)
        case .h5:
            return .charterFont(weight: .bold, size: 14)
        case .h6:
            return .charterFont(weight: .bold, size: 10)
        case .italic:
            return .charterFont(weight: .regular, size: 16)
        case .bold:
            return .charterFont(weight: .bold, size: 16)
        case .small:
            return .charterFont(weight: .regular, size: 14)
        case .li:
            return .charterFont(weight: .regular, size: 16)
        }
    }
}

public class Node {
    public let css: [String: [String: String]]
    
    public init(css: [String : [String : String]]) {
        self.css = css
    }
}

public class BlockNode: Node {
    public let children: [Node]
    
    public init(children: [Node], css: [String: [String: String]] = [:]) {
        self.children = children
        super.init(css: css)
    }
}

public class ParentNode: Node {
    public let children: [Node]
    
    public init(children: [Node], css: [String: [String: String]] = [:]) {
        self.children = children
        super.init(css: css)
    }
}

public class TextNode: Node {
    public let text: String
    public let types: [TextType]
    
    public init(text: String, types: [TextType] = [], css: [String: [String: String]] = [:]) {
        self.text = text
        self.types = types
        super.init(css: css)
    }
}

public class ImageNode: Node {
    public let src: String
    public let altTitle: String?
    
    public init(src: String, altTitle: String? = nil, css: [String: [String: String]] = [:]) {
        self.src = src
        self.altTitle = altTitle
        super.init(css: css)
    }
}

public class FieldsetNode: Node {
    public let nodes: [Node]
    
    public init(nodes: [Node], css: [String: [String: String]] = [:]) {
        self.nodes = nodes
        super.init(css: css)
    }
}

public class AnchorNode: TextNode {
    public let href: String
    
    public init(href: String, text: String, types: [TextType] = [], css: [String: [String: String]] = [:]) {
        self.href = href
        super.init(text: text, types: types, css: css)
    }
}
