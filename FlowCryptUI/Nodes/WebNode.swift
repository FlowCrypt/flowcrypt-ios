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
    private var webView: WKWebView!

    override init() {
        super.init()
        self.setViewBlock {
            WKWebView()
        }
    }

    override func didLoad() {
        super.didLoad()
        guard let webView = self.view as? WKWebView else { return }
        // Load HTML content
        let htmlContent = "<html>Your HTML Content</html>"
        webView.loadHTMLString(htmlContent, baseURL: nil)
    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        // Layout spec for the web view
        return ASWrapperLayoutSpec(layoutElement: self)
    }
}
