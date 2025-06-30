//
//  SwiftUIView.swift
//  
//
//  Created by Inumaki on 26.11.23.
//

import SwiftUI

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

public struct Styling {
    public let fontSize: Double
    public let fontWeight: Font.Weight
    
    public init(fontSize: Double = 16.0, fontWeight: Font.Weight = .regular) {
        self.fontSize = fontSize
        self.fontWeight = fontWeight
    }
}

struct AnyMyView: View {

    private let internalView: AnyView
    let originalView: Any

    init<V: View>(_ view: V) {
        internalView = AnyView(view)
        originalView = view
    }
    
    var body: some View {
        internalView
    }
}

// Define the HTML-like tags and their attributes
public enum HTMLTag {
    case p(content: [HTMLComponent])
    case em(content: [HTMLComponent])
    case span(content: [HTMLComponent], style: Styling?)
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

struct HTMLWrapper<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
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
                RichText(text: text)
            case .tag(let tag):
                renderHTMLTag(tag)
            }
        }
    }

    
    private func renderHTMLTag(_ tag: HTMLTag) -> AnyView {
        switch tag {
        case .p(let content):
            return AnyView(
                VStack {
                    renderText(content)
                }
            )
        case .span(let content, let main_style):
            let concatenatedText = content.compactMap { component -> Text? in
                switch component {
                case .text(let text, let style, let size):
                    
                    let str = LocalizedStringKey(text.softHyphenated().stringByRemovingHTMLTags())
                    
                    return Text(str)
                        .font(.custom("Charter", size: size))
                        .fontWeight(style)
                case .tag(.span(let s_content, let style)):
                    
                    let render = renderHTMLTag(.span(content: s_content, style: style)) as? AnyMyView
                    /*if let textView = render?.originalView as? Text {
                        return textView
                            .font(.custom("Charter", size: style?.fontSize ?? 16.0))
                            .fontWeight(style?.fontWeight)
                    }*/
                    return nil
                case .tag(.br):
                    return Text("\n")
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
            )
        case .h1(let text):
            return AnyView (
                VStack(spacing: 0) {
                    RichText(text: "<b>\(text.softHyphenated())</b>", fontSize: 32)
                        .multilineTextAlignment(.leading)
                }
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                )
        case .h2(let text):
            return AnyView(
                VStack(spacing: 0) {
                    RichText(text: "<b>\(text.softHyphenated())</b>", fontSize: 22)
                        .multilineTextAlignment(.leading)
                }
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                )
        case .h3(let text):
            return AnyView(
                VStack(spacing: 0) {
                    RichText(text: "<b>\(text.softHyphenated())</b>", fontSize: 20)
                        .multilineTextAlignment(.leading)
                }
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
            )
        case .h4(let text):
            return AnyView(
                VStack(spacing: 0) {
                    RichText(text: "<b>\(text.softHyphenated())</b>", fontSize: 18)
                        .multilineTextAlignment(.leading)
                }
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                )
        case .br:
            return AnyView(
                Spacer()
                    .frame(height: 16)
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
                LazyVStack(spacing: 0) {
                    ForEach(0..<items.count, id: \.self) { index in
                        let t = items[index]
                        
                        HStack(alignment: .top) {
                            Circle()
                                .frame(width: 4, height: 4)
                                .padding(.top, 8)
                            
                            switch t {
                            case .text(let str, let weight, let size):
                                Text(str)
                                    .font(.custom("Charter", size: size))
                                    .fontWeight(weight)
                            case .tag(let tag):
                                renderHTMLTag(tag)
                                    .padding(.bottom, -8)
                                    .padding(.top, -8)
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
                LazyVStack(spacing: 0) {
                    ForEach(0..<items.count, id: \.self) { index in
                        let t = items[index]
                        
                        HStack(alignment: .top) {
                            Text("\(index + 1).")
                            
                            switch t {
                            case .text(let str, let weight, let size):
                                RichText(text: str)
                            case .tag(let tag):
                                renderHTMLTag(tag)
                                    .padding(.bottom, -8)
                                    .padding(.top, -8)
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
    
    private func renderText(_ content: [HTMLComponent]) -> some View {
        let concatenatedText = content.compactMap { component -> String? in
            switch component {
            case .text(let text, let style, let size):
                return text
                /*
                let str = LocalizedStringKey(text.softHyphenated().stringByRemovingHTMLTags())
                
                return Text(str)
                    .font(.custom("Charter", size: size))
                    .fontWeight(style)
                 */
            case .tag(.span(let s_content, let style)):
                return nil
                /*
                let render = renderHTMLTag(.span(content: s_content, style: style)) as? AnyMyView
                if let textView = render?.originalView as? Text {
                    return textView
                }
                return nil*/
            case .tag(.a(let text, let url)):
                return text
                /*
                let str = LocalizedStringKey(text.softHyphenated().stringByRemovingHTMLTags())
                
                return Text(str)
                    .foregroundColor(.blue)*/
            default:
                return nil
            }
        }
        
        return RichText(text: concatenatedText.joined())
            .padding(.vertical, 8)
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
                HTMLComponent.tag(.p(content: [
                    .tag(.span(
                        content: [
                            .tag(.span(content: [.text("Chapter 1:")], style: nil)),
                            .tag(.br),
                            .tag(.span(content: [.text("The Structure of")], style: nil)),
                            .tag(.br),
                            .tag(.span(content: [.text("Japanese Society")], style: nil)),
                        ],
                        style: Styling(
                            fontSize: 16 * 1.5,
                            fontWeight: .bold
                        )
                    ))
                ]))
                HTMLComponent.tag(.br)
                HTMLComponent.tag(.p(content: [
                    .tag(.span(content: [.text("I", .bold, 34), .text(" ", .bold, 22), .text("know this is kind of sudden, but, please, it will only take a moment."), .text("I want your honest opinion.")], style: Styling(fontSize: 16, fontWeight: .bold)))
                ]))
                HTMLComponent.tag(.p(content: [
                    .tag(.span(content: [.text("Are all human beings truly equal?")], style: Styling(fontSize: 16, fontWeight: .bold)))
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

struct HTMLDisplay3: View {
    let footnoteDescription = "<a href=\"chap_00002.xhtml#ref1\">[1]</a> <b>Dokja</b> can mean 'only child', 'reader' or 'individualist' in Korean."
    
    @State var showSheet: Bool = false
    @State var href: String = ""
    @State var title: String = ""
    
    var body: some View {
        ScrollView {
            HTMLTextView {
                HTMLComponent.tag(.div(content: [
                    .tag(.img(url: "https://media.discordapp.net/attachments/1110373752476270692/1181262048458444910/titlepage800.png")),
                    .tag(.h3(text: "<b>Chapter 1: Prologue - Three Ways to Survive in a Ruined World.</b>"))
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
        .overlay {
            ZStack(alignment: .bottom) {
                if showSheet {
                    Color.black.opacity(0.3)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                showSheet = false
                            }
                        }
                        .animation(.easeInOut, value: showSheet)
                        .transition(.opacity)
                }
                
                if showSheet {
                    VStack(alignment: .leading) {
                        HStack {
                            Text(title)
                                .font(.custom("Charter", size: 26))
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Button {
                                withAnimation(.spring(response: 0.3)) {
                                    showSheet = false
                                }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background {
                                        Circle()
                                            .fill(.regularMaterial)
                                    }
                            }
                        }
                        VStack {
                            RichText(text: footnoteDescription) { link, _, _ in
                                print(link ?? "HM")
                            }
                        }
                    }
                    .foregroundColor(.primary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .background(.regularMaterial)
                    .cornerRadius(12)
                    .padding()
                    .padding(.bottom)
                    .animation(.spring(response: 0.3), value: showSheet)
                    .transition(.move(edge: .bottom))
                }
            }
            .ignoresSafeArea()
        }
    }
}

#Preview("HTML Display") {
    Group {
        HTMLDisplay3()
    }
}
