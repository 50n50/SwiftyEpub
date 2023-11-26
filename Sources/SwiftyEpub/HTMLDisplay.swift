//
//  SwiftUIView.swift
//  
//
//  Created by Inumaki on 26.11.23.
//

import SwiftUI

// Define the HTML-like tags and their attributes
enum HTMLTag {
    case p(content: [HTMLComponent])
    case span(content: [HTMLComponent], style: String?)
    case img(url: String)
    case h2(text: String)
    case h4(text: String)
    case li(text: String)
    case a(text: String, url: String)
    case br
}

// Define the components for various HTML-like tags
enum HTMLComponent {
    case text(String)
    case tag(HTMLTag)
    
    var id: UUID {
        UUID()
    }
}

// Result builder for constructing SwiftUI views from HTML-like tags
@resultBuilder
struct HTMLBuilder {
    static func buildBlock(_ components: HTMLComponent...) -> [HTMLComponent] {
        components
    }
}

// Custom SwiftUI view to display HTML-like content
struct HTMLTextView: View {
    let content: [HTMLComponent]

    init(@HTMLBuilder content: () -> [HTMLComponent]) {
        self.content = content()
    }
    
    var body: some View {
        buildView(for: content)
    }

    @ViewBuilder
    private func buildView(for components: [HTMLComponent]) -> some View {
        ForEach(components, id: \.id) { component in
            switch component {
            case .text(let text):
                Text(text)
            case .tag(let tag):
                renderHTMLTag(tag)
            }
        }
    }

    @ViewBuilder
    private func renderHTMLTag(_ tag: HTMLTag) -> some View {
        switch tag {
        case .p(let content):
            VStack(alignment: .leading) {
                buildView(for: content)
            }
            .padding(.vertical, 5)
        case .span(let content, let style):
            buildView(for: content)
                .modifier(HTMLSpanStyle(style: style))
        case .img(let url):
            // Handle image - Placeholder for image view
            Text("Image: \(url)")
        case .h2(let text):
            Text(text)
                .font(.title2)
                .bold()
        case .h4(let text):
            Text(text)
                .font(.headline)
                .bold()
        case .li(let text):
            Text("• \(text)")
        case .a(let text, let url):
            // Handle hyperlink - Placeholder for link view
            Text("\(text) (\(url))")
                .foregroundColor(.blue)
                .underline()
        case .br:
            Text("\n")
        }
    }
}

// Modifier for applying styles to span elements
struct HTMLSpanStyle: ViewModifier {
    let style: String?

    func body(content: Content) -> some View {
        if let style = style {
            // Implement style parsing logic and apply here
            return content
        } else {
            return content
        }
    }
}

struct SwiftUIView: View {
    var body: some View {
        HTMLTextView {
            HTMLComponent.tag(.p(content: [
                .tag(.span(content: [.text("I know this is kind of sudden, but, please, it will only take a moment. "), .text("I want your honest opinion.")], style: "font-weight: bold; font-size: 1em")),
                .tag(.span(content: [.text("This is another span.")], style: "font-size: 1.5em"))
            ])),
            HTMLComponent.tag(.h2(text: "Heading 2")),
            HTMLComponent.text("Regular text."),
            HTMLComponent.tag(.br)
        }
        .padding()
    }
}

#Preview {
    SwiftUIView()
}
