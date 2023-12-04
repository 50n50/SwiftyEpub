//
//  SwiftUIView.swift
//  
//
//  Created by Inumaki on 26.11.23.
//

import SwiftUI
import Kingfisher

public struct Padding {
    public let top: Double
    public let bottom: Double
    public let left: Double
    public let right: Double
    
    public init(top: Double = 0.0, bottom: Double = 0.0, left: Double = 0.0, right: Double = 0.0) {
        self.top = top
        self.bottom = bottom
        self.left = left
        self.right = right
    }
}

// Define the HTML-like tags and their attributes
public enum HTMLTag {
    case p(content: [HTMLComponent])
    case span(content: [HTMLComponent], style: String?)
    case img(url: String)
    case h1(text: String)
    case h2(text: String)
    case h3(text: String)
    case h4(text: String)
    case li(text: String)
    case ul(items: [HTMLComponent])
    case ol(items: [HTMLComponent])
    case a(text: String, url: String)
    case br
    case fieldset(content: [HTMLComponent])
    case div(content: [HTMLComponent], padding: Padding?)
}

// Define the components for various HTML-like tags
public enum HTMLComponent {
    case text(String, Font.Weight = .regular, CGFloat = 16.0)
    case tag(HTMLTag)
    
    public var id: UUID {
        UUID()
    }
}

// Result builder for constructing SwiftUI views from HTML-like tags
@resultBuilder
public struct HTMLBuilder {
    public static func buildBlock(_ components: HTMLComponent...) -> [HTMLComponent] {
        components
    }
}

// Custom SwiftUI view to display HTML-like content
public struct HTMLTextView: View {
    public let content: [HTMLComponent]

    public init(content: [HTMLComponent]) {
        self.content = content
    }
    
    public init(@HTMLBuilder content: () -> [HTMLComponent]) {
        self.content = content()
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            buildView(for: content)
                .font(.custom("Charter", size: 16))
        }
    }

    @ViewBuilder
    private func buildView(for components: [HTMLComponent]) -> some View {
        ForEach(components, id: \.id) { component in
            switch component {
            case .text(let text, let style, let size):
                Text(text)
            case .tag(let tag):
                renderHTMLTag(tag)
            }
        }
    }

    private func renderHTMLTag(_ tag: HTMLTag) -> some View {
        switch tag {
        case .p(let content):
            let concatenatedText = content.compactMap { component -> Text? in
                switch component {
                case .text(let text, let style, let size):
                    let str = LocalizedStringKey(text.softHyphenated().stringByRemovingHTMLTags())
                    
                    return Text(str)
                        .fontWeight(style)
                case .tag(.span(let s_content, let style)):
                    let conc: [Text] = s_content.compactMap { c in
                        if case let .text(text, style, size) = c {
                            let str = LocalizedStringKey(text.softHyphenated().stringByRemovingHTMLTags())
                            
                            return Text(str)
                                .font(.custom("Charter", size: size))
                                .fontWeight(style)
                        }
                        return nil
                    }
                    
                    return conc.reduce(Text("")) { $0 + Text("") + $1 }
                case .tag(.a(let text, let url)):
                    let str = LocalizedStringKey(text.softHyphenated().stringByRemovingHTMLTags())
                    
                    return Text(str)
                        .foregroundColor(.blue)
                default:
                    return nil
                }
            }

            return AnyView(
                concatenatedText
                    .reduce(Text("")) { $0 + Text("") + $1 }
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 8)
                    .padding(.top, 8)
            )
        case .h1(let text):
            return AnyView(
                Text(text.softHyphenated())
                    .font(.custom("Charter", size: 32))
                    .fontWeight(.bold)
                    .padding(.bottom, 8)
                    .padding(.top, 8)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                )
        case .h2(let text):
            return AnyView(
                Text(text.softHyphenated())
                    .font(.custom("Charter", size: 22))
                    .fontWeight(.bold)
                    .padding(.bottom, 8)
                    .padding(.top, 8)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                )
        case .h3(let text):
            return AnyView(
                Text(text.softHyphenated())
                    .font(.custom("Charter", size: 20))
                    .fontWeight(.bold)
                    .padding(.bottom, 8)
                    .padding(.top, 8)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                )
        case .h4(let text):
            return AnyView(
                Text(text.softHyphenated())
                    .font(.custom("Charter", size: 18))
                    .fontWeight(.bold)
                    .padding(.bottom, 8)
                    .padding(.top, 8)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                )
        case .br:
            return AnyView(
                Spacer()
                    .frame(height: 16)
                    .padding(.bottom, 8)
                    .padding(.top, 8)
            )
        case .img(let url):
            return AnyView(
                KFImage(URL(string: url))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(.bottom, 8)
                    .padding(.top, 8)
            )
        case .li(let text):
            return AnyView(
                Text(text.softHyphenated())
                    .font(.custom("Charter", size: 15))
                    .padding(.bottom, 8)
                    .padding(.top, 8)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            )
        case .a(let text, let url):
            return AnyView(
                Text(text.softHyphenated().stringByRemovingHTMLTags())
                    .font(.custom("Charter", size: 15))
                    .padding(.bottom, 8)
                    .padding(.top, 8)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(.blue)
            )
        case .fieldset(let content):
            return AnyView(
                VStack(spacing: 0) {
                    ForEach(0..<content.count, id: \.self) { index in
                        let t = content[index]
                        
                        switch t {
                        case .text(let str, let weight, let size):
                            Text(str)
                                .font(.custom("Charter", size: size))
                                .fontWeight(weight)
                                .frame(maxWidth: .infinity)
                        case .tag(let tag):
                            renderHTMLTag(tag)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(8)
                .background {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.white, lineWidth: 0.5)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 8)
                .padding(.top, 8)
            )
        case .div(let content, let padding):
            return AnyView(
                VStack(spacing: 0) {
                    ForEach(0..<content.count, id: \.self) { index in
                        let t = content[index]
                        
                        switch t {
                        case .text(let str, let weight, let size):
                            Text(str)
                                .font(.custom("Charter", size: size))
                                .fontWeight(weight)
                        case .tag(let tag):
                            renderHTMLTag(tag)
                        }
                    }
                }
                .padding(.top, padding?.top ?? 0.0)
                .padding(.bottom, padding?.bottom ?? 0.0)
                .padding(.leading, padding?.left ?? 0.0)
                .padding(.trailing, padding?.right ?? 0.0)
                .padding(.bottom, 8)
                .padding(.top, 8)
            )
        case .ul(let items):
            return AnyView(
                VStack(spacing: 0) {
                    ForEach(0..<items.count, id: \.self) { index in
                        let t = items[index]
                        
                        HStack {
                            Circle()
                                .frame(width: 4, height: 4)
                            
                            switch t {
                            case .text(let str, let weight, let size):
                                Text(str)
                                    .font(.custom("Charter", size: size))
                                    .fontWeight(weight)
                            case .tag(let tag):
                                renderHTMLTag(tag)
                                    .padding(.bottom, -8)
                            }
                        }
                        .padding(.leading, 20)
                    }
                }
                .padding(.bottom, 8)
                .padding(.top, 8)
            )
        case .ol(let items):
            return AnyView(
                VStack(spacing: 0) {
                    ForEach(0..<items.count, id: \.self) { index in
                        let t = items[index]
                        
                        HStack(alignment: .top) {
                            Text("\(index + 1).")
                            
                            switch t {
                            case .text(let str, let weight, let size):
                                Text(str)
                                    .font(.custom("Charter", size: size))
                                    .fontWeight(weight)
                            case .tag(let tag):
                                renderHTMLTag(tag)
                                    .padding(.bottom, -8)
                            }
                        }
                    }
                }
                .padding(.bottom, 8)
                .padding(.top, 8)
            )
        default:
            return AnyView(EmptyView())
        }
    }

    private func concatenateStyledText(from components: [HTMLComponent], with style: String?) -> String {
        let concatenatedText = components.compactMap { component -> String? in
            if case let .text(text, style, size) = component {
                return text
            }
            return nil
        }.joined()

        if let style = style {
            // Apply styling to the concatenated text here
            // Parse the style and apply the appropriate styling to the text
            // You might need to parse different styles and apply SwiftUI modifiers accordingly
            // For instance, set different font sizes, weights, etc.
        }

        return concatenatedText
    }
}

// Modifier for applying styles to span elements
public struct HTMLSpanStyle: ViewModifier {
    public let style: String?

    public func body(content: Content) -> some View {
        if let style = style {
            // Implement style parsing logic and apply here
            return content
        } else {
            return content
        }
    }
}

struct HTMLDisplay: View {
    var body: some View {
        ScrollView {
            HTMLTextView {
                HTMLComponent.tag(.h2(text: "Chapter 1:\nThe Structure of\nJapanese Society"))
                HTMLComponent.tag(.br)
                HTMLComponent.tag(.p(content: [
                    .tag(.span(content: [.text("I", .bold, 34), .text("know this is kind of sudden, but, please, it will only take a moment."), .text("I want your honest opinion.")], style: "font-weight: bold; font-size: 1em"))
                ]))
                HTMLComponent.tag(.p(content: [
                    .tag(.span(content: [.text("Are all human beings truly equal?")], style: "font-weight: bold; font-size: 1em"))
                ]))
            }
            .padding(.horizontal, 30)
        }
    }
}

struct HTMLDisplay2: View {
    var body: some View {
        ScrollView {
            HTMLTextView {
                HTMLComponent.tag(.div(content: [
                    .tag(.img(url: "https://media.discordapp.net/attachments/1110373752476270692/1181262048458444910/titlepage800.png")),
                    .tag(.h3(text: "Chapter 1: Prologue - Three Ways to Survive in a Ruined World."))
                ], padding: Padding(bottom: 16.0)))
                HTMLComponent.tag(.p(content: [.text("「There are three ways to survive in a ruined world. I have forgotten some of them now. However, one thing is certain: you who are currently reading these words will survive.")]))
                HTMLComponent.tag(.p(content: [.text("–Three Ways to Survive in a Ruined World [Complete]」")]))
                HTMLComponent.tag(.p(content: [.text("A web novel platform filled the screen of my old smartphone. I scrolled down and then up again. How many times have I been doing this?")]))
                HTMLComponent.tag(.p(content: [.text("\"Really? This is the end?\"")]))
                HTMLComponent.tag(.p(content: [.text("I looked again, and the 'complete' was unmistakable. The story was over.")]))
                HTMLComponent.tag(.fieldset(content: [
                    .tag(.p(content: [.text("[Three Ways to Survive in a Ruined World]")])),
                    .tag(.p(content: [.text("Author: tls123")])),
                    .tag(.p(content: [.text("3,149 chapters.")]))
                ]))
                HTMLComponent.tag(.ul(items: [
                    .tag(.li(text: "Apple Books")),
                    .tag(.li(text: "Kindle (Paperwhite 4, Firmware 5.12.3)")),
                    .tag(.li(text: "KOReader - HTML5 style needs to be enabled!")),
                ]))
                HTMLComponent.tag(.ol(items: [
                    .tag(.li(text: "Apple Books")),
                    .tag(.li(text: "Kindle (Paperwhite 4, Firmware 5.12.3)")),
                    .tag(.li(text: "KOReader - HTML5 style needs to be enabled!")),
                ]))
                HTMLComponent.tag(.p(content: [
                    .text("\"I'm "),
                    .tag(.a(text: "Dokja", url: "")),
                    .text("¹.\"")
                ]))
            }
            .padding(.horizontal, 30)
        }
    }
}

#Preview("HTML Display") {
    Group {
        HTMLDisplay2()
    }
}
