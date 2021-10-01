//
//  WebViewController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12/10/19.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit
import WebKit

/**
 * InApp WebViewController to show web content. Used for showing privacy policy etc in splash screen and settings
 */
final class WebViewController: UIViewController {
    private lazy var webView = WKWebView()

    private var url: URL?

    init(url: URL?) {
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = webView
        webView.backgroundColor = .backgroundColor
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        webView.allowsBackForwardNavigationGestures = false
        guard let lik = url else { return }
        webView.load(URLRequest(url: lik))
    }
}
