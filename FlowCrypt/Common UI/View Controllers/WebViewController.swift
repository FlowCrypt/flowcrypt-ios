//
//  WebViewController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12/10/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import UIKit
import WebKit

final class WebViewController: UIViewController {
    private lazy var webView = WKWebView()
    
    private var url: URL?
    
    init(url: URL?) {
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        self.view = webView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.allowsBackForwardNavigationGestures = false
        guard let lik = url else { return }
        webView.load(URLRequest(url: lik))
    }
}
