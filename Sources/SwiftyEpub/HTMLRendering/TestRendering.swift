//
//  Test.swift
//  ChoutenRedesign
//
//  Created by Inumaki on 11.01.24.
//

import UIKit
import SwiftUI

extension View {
    /// Applies the given transform if the given condition evaluates to `true`.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

class ViewController: UIViewController {
    let label = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()

        label.numberOfLines = 0
        // Set the font to Iowan Old Style
        label.font = UIFont(name: "Iowan Old Style", size: UIFont.systemFontSize)
        label.attributedText = createAttributedString()
        label.textColor = .label
        
        view.addSubview(label)

        // Set up constraints based on your layout requirements
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: view.topAnchor),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    func createAttributedString(_ fontSize: CGFloat? = nil) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: "I know this is kind of sudden, but, please, it will only take a moment. I want your honest opinion.")
        
        attributedString.addAttribute(NSAttributedString.Key.font, value: UIFont(name: "Iowan Old Style", size: (fontSize ?? UIFont.systemFontSize) * 2.5), range: NSRange(location: 0, length: 1))
/*
        if let image = UIImage(named: "image_213.jpg", in: .module, with: .none) {
            attributedString.append(addImage(image))
        }
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.hyphenationFactor = 1.0 // Set hyphenation factor to enable soft hyphenation

        let textString = "?!Lorem ipsum dolor sit amet, consectetur adipiscing elit. Proin convallis sapien vel orci lobortis laoreet. Ut pretium dapibus sodales. Nulla viverra eget leo eu convallis."

        let textAttributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle,
            .font: label.font! // Ensure the font is set correctly
        ]

        let textAttributedString = NSAttributedString(string: textString, attributes: textAttributes)
        attributedString.append(textAttributedString)
*/
        return attributedString
    }
    
    func addImage(_ image: UIImage) -> NSAttributedString {
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = image

        // Adjust the baseline offset to center the image vertically
        let mid = (UIFont.systemFontSize + label.font!.descender) / 2
        
        imageAttachment.bounds = CGRect(x: 0, y: mid * (label.font.pointSize / 16.0), width: image.size.width * (label.font.pointSize / 16.0), height: image.size.height * (label.font.pointSize / 16.0))

        return NSAttributedString(attachment: imageAttachment)
    }
}

struct TestRepresentable: UIViewControllerRepresentable {
    @Binding var fontSize: CGFloat

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = ViewController()
        viewController.label.font = UIFont.systemFont(ofSize: fontSize)
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        guard let viewController = uiViewController as? ViewController else { return }
        viewController.label.font = UIFont(name: "Iowan Old Style", size: fontSize)
        viewController.label.attributedText = viewController.createAttributedString(fontSize)
    }
}

struct TestStack: View {
    @State private var fontSize: CGFloat = 16.0
    
    @State var showSettings: Bool = false
    @State var padding: Bool = false

    var body: some View {
        VStack {
            Text("Chapter 1:\nThe Structure of\nJapanese Society")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            TestRepresentable(fontSize: $fontSize)
                .if(padding) { view in
                    view
                        .padding(8)
                        .overlay {
                            Rectangle()
                                .stroke(.primary, lineWidth: 0.5)
                        }
                        .padding(20)
                }
                .padding(20)

            Button {
                padding.toggle()
                
                //showSettings = true
            } label: {
                Text("Show Settings")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 20)
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.regularMaterial)
                            .overlay {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(.primary, lineWidth: 0.5)
                            }
                    }
            }
            
            Slider(value: $fontSize, in: 12...26, step: 2)
                .padding()
        }
        .background(.background)
        .foregroundColor(.primary)
        .sheet(isPresented: $showSettings) {
            VStack {
                HStack {
                    Text("Themes & Settings")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button {
                        
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .padding(8)
                            .background {
                                Circle()
                                    .fill(.regularMaterial)
                                    .overlay {
                                        Circle()
                                            .stroke(.primary, lineWidth: 0.5)
                                    }
                            }
                    }
                }
                
                HStack {
                    HStack {
                        Button {
                            fontSize -= 2.0
                        } label: {
                            Text("A")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .opacity(fontSize < 14.0 ? 0.7 : 1.0)
                        }
                        .frame(width: 80, height: 24)
                        .disabled(fontSize < 14.0)
                        
                        Rectangle()
                            .fill(.primary)
                            .frame(width: 1, height: 24)
                            .padding(.vertical, 8)
                        
                        Button {
                            fontSize += 2.0
                        } label: {
                            Text("A")
                                .font(.title3)
                                .fontWeight(.bold)
                                .opacity(fontSize > 24.0 ? 0.7 : 1.0)
                        }
                        .frame(width: 80, height: 24)
                        .disabled(fontSize > 24.0)
                    }
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.regularMaterial)
                            .overlay {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(.primary, lineWidth: 0.5)
                            }
                    }
                    
                    Spacer()
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(.regularMaterial)
            .foregroundColor(.primary)
            //.presentationDetents([.medium])
        }
    }
}

#Preview {
    TestStack()
}
