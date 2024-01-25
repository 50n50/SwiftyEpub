//
//  SwiftUIView.swift
//  
//
//  Created by Inumaki on 06.12.23.
//

import SwiftUI
import Kingfisher

struct MarkdownTextView: UIViewRepresentable {
    let attributedText: NSAttributedString
    let onTapLink: (URL) -> Void

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.delegate = context.coordinator
        textView.attributedText = attributedText
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.attributedText = attributedText
        uiView.delegate = context.coordinator
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        let parent: MarkdownTextView

        init(_ parent: MarkdownTextView) {
            self.parent = parent
        }

        func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
            parent.onTapLink(URL)
            return false
        }
    }
}

struct UniversalLabelView: UIViewRepresentable {
    
    private(set) var html: String
    @Binding var dynamicHeight: CGFloat
    var action: ((String, String?) -> Void)
    
    var mutatingWrapper = MutatingWrapper()
    class MutatingWrapper {
        var fontSize: CGFloat = 16
        var textAlignment: NSTextAlignment = .left
        var numberOfLines: Int = 0
        var textColor: UIColor = .label
        var linkColor: UIColor = .systemBlue
    }
    
    func makeUIView(context: UIViewRepresentableContext<Self>) -> UniversalLabel {
        let label = UniversalLabel()
        label.isUserInteractionEnabled = true

        label.numberOfLines = mutatingWrapper.numberOfLines
        label.textFontSize = mutatingWrapper.fontSize
        label.textAlignment = mutatingWrapper.textAlignment
        label.textColor = mutatingWrapper.textColor
        label.linkColor = mutatingWrapper.linkColor
        label.lineBreakMode = .byWordWrapping
        
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        label.onPress { url, title in
            guard let url = url else { return }
            action(url, title)
        }

        return label
    }

    func updateUIView(_ uiView: UniversalLabel, context: UIViewRepresentableContext<Self>) {
        uiView.html = html
        uiView.numberOfLines = mutatingWrapper.numberOfLines

        DispatchQueue.main.async {
            dynamicHeight = uiView.sizeThatFits(
                CGSize(
                    width: uiView.bounds.width,
                    height: CGFloat.greatestFiniteMagnitude
                )
            ).height
        }
    }
    
    func textFontSize(_ fontSize: CGFloat) -> Self {
        mutatingWrapper.fontSize = fontSize
        return self
    }
    
    func textAlignment(_ textAlignment: NSTextAlignment) -> Self {
        mutatingWrapper.textAlignment = textAlignment
        return self
    }
    
    func textColor(_ textColor: UIColor) -> Self {
        mutatingWrapper.textColor = textColor
        return self
    }
    
    func linkColor(_ linkColor: UIColor) -> Self {
        mutatingWrapper.linkColor = linkColor
        return self
    }
    
    
    func lineLimit(_ number: Int) -> Self {
        mutatingWrapper.numberOfLines = number
        return self
    }
}

public struct RichText: View {
    let text: String
    let fontSize: Double
    @State private var height: CGFloat = .zero
    var completionHandler: ((String?, String?, Bool) -> Void)? // Optional completion handler
        
    public init(text: String, fontSize: Double = 16, completionHandler: ((String?, String?, Bool) -> Void)? = nil) {
        self.text = text
        self.fontSize = fontSize
        self.completionHandler = completionHandler
    }
    
    public init(text: String, fontSize: Double = 16) {
        self.text = text
        self.fontSize = fontSize
    }
    
    public var body: some View {
        UniversalLabelView(html: text, dynamicHeight: $height) { url, title in
            completionHandler?(url, title, true)
        }
        .textFontSize(fontSize)
        .frame(maxWidth: .infinity, minHeight: height, maxHeight: height)
    }
}

struct RichTextWrapper: View {
    let text = "<p>\"I'm <a href=\"chap_00002.xhtml#note1\">Dokja</a>¹.\"</p>"
    let text2 = "<b>Chapter 1: Prologue - Three Ways to Survive in a Ruined World.</b>"
    
    let footnoteDescription = "<a href=\"chap_00002.xhtml#ref1\">[1]</a> <b>Dokja</b> can mean 'only child', 'reader' or 'individualist' in Korean."
    
    @State var showSheet: Bool = false
    @State var href: String = ""
    @State var title: String = ""
    
    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 12) {
                    KFImage(URL(string: "https://media.discordapp.net/attachments/1110373752476270692/1181262048458444910/titlepage800.png"))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(.top, 80)
                    RichText(text: text2, fontSize: 22)
                    RichText(text: "「There are three ways to survive in a ruined world. I have forgotten some of them now. However, one thing is certain: you who are currently reading these words will survive.")
                    RichText(text: text) { link, title, open in
                        href = link ?? "Nothing"
                        withAnimation(.spring(response: 0.3)) {
                            showSheet = open
                        }
                        
                        self.title = title ?? ""
                    }
                }
                .padding(.horizontal, 20)
            }
            .frame(maxWidth: proxy.size.width > 600 ? proxy.size.width / 2 : .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
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

struct TestText: View {
    let markdownText = "This is a [link](https://www.example.com) in Markdown format."

    func renderMarkdown() -> NSAttributedString {
        // Logic to convert markdownText to NSAttributedString
        let attributedString = NSMutableAttributedString(string: markdownText)
        // Apply formatting for links, bold, italics, etc. using attributes
        return attributedString
    }

    var body: some View {
        MarkdownTextView(attributedText: renderMarkdown()) { url in
            // Handle link tap here
            print("Tapped link: \(url)")
            // Implement your action for handling the link tap
        }
    }
}

#Preview {
    //RichTextWrapper()
    TestText()
}
