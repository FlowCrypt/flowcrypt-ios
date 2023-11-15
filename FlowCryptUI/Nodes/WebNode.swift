//
//  WebNode.swift
//  FlowCryptUI
//
//  Created by Ioan Moldovan on 11/14/23
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import WebKit

class WebNode: ASDisplayNode {
    private var webView: WKWebView?

    override init() {
        super.init()
        automaticallyManagesSubnodes = true
    }

    override func didLoad() {
        super.didLoad()
        DispatchQueue.main.async { [weak self] in
            let webView = WKWebView()
            self?.webView = webView
            self?.view.addSubview(webView)
        }
    }

    override func layout() {
        super.layout()
        DispatchQueue.main.async { [weak self] in
            self?.webView?.frame = self?.bounds ?? .zero
        }
    }

    func loadHTMLContent(_ htmlContent: String) {
        DispatchQueue.main.async { [weak self] in
            self?.webView?.loadHTMLString(htmlContent, baseURL: nil)
        }
    }
}
