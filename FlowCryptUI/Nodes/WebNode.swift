//
//  WebNode.swift
//  FlowCryptUI
//
//  Created by Ioan Moldovan on 11/16/23
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import WebKit

class CustomWebViewNode: ASDisplayNode {
    private let webViewNode: ASDisplayNode

    override init() {
        // Create a display node for the WKWebView
        webViewNode = ASDisplayNode { () -> UIView in
            if Thread.isMainThread {
                return WKWebView()
            } else {
                var webView: WKWebView?
                DispatchQueue.main.sync {
                    webView = WKWebView()
                }
                return webView ?? UIView()
            }
        }

        super.init()

        // Add webViewNode as a subnode
        self.addSubnode(webViewNode)

        // Style properties for webViewNode
        webViewNode.style.flexGrow = 1.0
        webViewNode.style.flexShrink = 1.0
    }

    func setHtml(_ htmlContent: String) {
        DispatchQueue.main.async {
            // Load HTML content into the WKWebView
            if let webView = self.webViewNode.view as? WKWebView {
                webView.navigationDelegate = self
                webView.loadHTMLString(htmlContent, baseURL: nil)
            }
        }
    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        // Use a simple layout spec to manage the webViewNode's size and position
        return ASWrapperLayoutSpec(layoutElement: webViewNode)
    }
}

extension CustomWebViewNode: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.evaluateContentHeight(webView: webView)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated {
            if let url = navigationAction.request.url,
               UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
                return
            }
        }
        decisionHandler(.allow)
    }

    private func evaluateContentHeight(webView: WKWebView) {
        webView.evaluateJavaScript("document.documentElement.scrollHeight", completionHandler: { [weak self] result, error in
            guard let self, let height = result as? CGFloat else {
                return
            }

            DispatchQueue.main.async {
                self.updateNodeHeight(height)
            }
        })
    }

    private func updateNodeHeight(_ height: CGFloat) {
        self.style.preferredSize = CGSize(width: self.calculatedSize.width, height: height)
        self.setNeedsLayout()
        self.supernode?.setNeedsLayout()
    }
}
