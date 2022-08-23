//
//  AttachmentViewController.swift
//  FlowCrypt
//
//  Created by Evgenii Kyivskyi on 11/16/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit
import WebKit
import FlowCryptUI
import FlowCryptCommon

@MainActor
final class AttachmentViewController: UIViewController {

    private lazy var logger = Logger.nested(Self.self)

    private let file: MessageAttachment
    private let shouldShowDownloadButton: Bool

    private let filesManager: FilesManagerType
    private lazy var attachmentManager = AttachmentManager(
        controller: self,
        filesManager: filesManager
    )

    private lazy var webView: WKWebView = {
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = false

        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences = preferences

        let view = WKWebView(frame: .zero, configuration: configuration)
        view.navigationDelegate = self
        view.backgroundColor = .backgroundColor
        view.allowsLinkPreview = false
        view.accessibilityIdentifier = "aid-attachment-web-view"
        return view
    }()

    private lazy var textView: UITextView = {
        let textView = UITextView(frame: .zero)
        textView.textContainerInset = .deviceSpecificTextInsets(top: 16, bottom: 16)
        textView.isEditable = false
        textView.font = .systemFont(ofSize: 14)
        textView.textColor = .textColor
        textView.backgroundColor = .backgroundColor
        textView.accessibilityIdentifier = "aid-attachment-text-view"
        return textView
    }()

    private lazy var errorLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.text = "no_preview_avalable".localized
        label.isHidden = true
        label.textColor = .textColor
        label.font = .systemFont(ofSize: 12)
        return label
    }()

    private var encodedContentRules: String {
        """
        [{
            "trigger": {
                "url-filter": ".*"
            },
            "action": {
                "type": "block"
            }
        }]
        """
    }

    private var isNavigated = false
    private var didLayoutSubviews = false

    init(
        file: MessageAttachment,
        shouldShowDownloadButton: Bool = true,
        filesManager: FilesManagerType = FilesManager()
    ) {
        self.file = file
        self.shouldShowDownloadButton = shouldShowDownloadButton
        self.filesManager = filesManager
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationBar()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard !didLayoutSubviews else { return }
        didLayoutSubviews = true

        renderAttachment()
    }

    private func setupNavigationBar() {
        title = file.name

        guard shouldShowDownloadButton else { return }

        let imageConfiguration = UIImage.SymbolConfiguration(font: .systemFont(ofSize: 24, weight: .light))
        let image = UIImage(systemName: "square.and.arrow.down", withConfiguration: imageConfiguration)

        navigationItem.rightBarButtonItem = NavigationBarItemsView(
            with: [
                NavigationBarItemsView.Input(
                    image: image?.tinted(.gray),
                    accessibilityId: "aid-save-attachment-to-device",
                    onTap: { [weak self] in self?.downloadAttachment() }
                )
            ]
        )
    }

    private func renderAttachment() {
        switch file.type {
        case "text/plain":
            showTextAttachment()
        default:
            renderAttachmentData()
        }
    }

    private func showTextAttachment() {
        view.addSubview(textView)
        view.constrainToEdges(textView)
        textView.text = file.data?.toStr()
        textView.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: false)
    }

    private func renderAttachmentData() {
        view.addSubview(webView)
        webView.addSubview(errorLabel)

        view.constrainToEdges(webView)
        webView.constrainToEdges(errorLabel)

        showSpinner()

        Task {
            do {
                try await setContentRules()
                try load()
            } catch {
                logger.logError("Preview Failed due to \(error.localizedDescription)")
                // todo - exact error should be surfaced to user?
                errorLabel.isHidden = false
                hideSpinner()
            }
        }
    }

    private func downloadAttachment() {
        Task {
            await attachmentManager.download(file)
        }
    }
}

extension AttachmentViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        errorLabel.isHidden = false
        hideSpinner()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        hideSpinner()
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        guard
            navigationAction.request.url?.scheme == "data",
            !isNavigated
        else { return .cancel }

        isNavigated = true
        return .allow
    }
}

private extension AttachmentViewController {

    private func setContentRules() async throws {
        guard let list = try await WKContentRuleListStore.default().compileContentRuleList(
            forIdentifier: "blockRules",
            encodedContentRuleList: encodedContentRules
        ) else {
            throw AppErr.general("Could not produce a content rule list")
        }

        webView.configuration.userContentController.removeAllContentRuleLists()
        webView.configuration.userContentController.add(list)
    }

    private func load() throws {
        let encoderTrace = Trace(id: "base64 encoding")
        guard let data = file.data,
              let url = URL(string: "data:\(file.name.mimeType);base64,\(data.base64EncodedString())") else {
            throw AppErr.general("Could not produce a data URL to preview this file")
        }
        logger.logDebug("base64 encoding time is \(encoderTrace.finish())")
        webView.load(URLRequest(url: url))
    }
}
