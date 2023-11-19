//
//  File.swift
//  
//
//  Created by Inumaki on 18.11.23.
//

import UIKit
import WebKit

class HTMLContentLoader: NSObject, WKNavigationDelegate {
    static func getContentHeight(htmlString: String, cssString: String, completion: @escaping (CGFloat?) -> Void) {
        let webView = WKWebView(frame: .zero)
        let contentLoader = HTMLContentLoader()
        webView.navigationDelegate = contentLoader

        let htmlWithStyle = "<html><head><style>\(cssString)</style></head><body>\(htmlString)</body></html>"
        webView.loadHTMLString(htmlWithStyle, baseURL: nil)

        let window = UIApplication.shared.windows.first { $0.isKeyWindow }
        window?.addSubview(webView)

        var contentHeight: CGFloat?

        contentLoader.didFinishLoading = { height in
            contentHeight = height
            webView.removeFromSuperview()
            completion(contentHeight)
        }
    }

    private var didFinishLoading: ((CGFloat?) -> Void)?

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript("document.body.scrollHeight") { [weak self] result, error in
            if let height = result as? CGFloat {
                print("gotHeight")
                self?.didFinishLoading?(height)
            } else {
                self?.didFinishLoading?(nil)
                print("Failed to get content height: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
}
