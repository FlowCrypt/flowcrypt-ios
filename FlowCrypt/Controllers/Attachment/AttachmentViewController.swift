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
import Combine
import FlowCryptCommon

@MainActor
final class AttachmentViewController: UIViewController {

    private lazy var webView = WKWebView()
    private let file: FileType
    private let shouldShowDownloadButton: Bool

    private let filesManager: FilesManagerType
    private lazy var attachmentManager = AttachmentManager(
        controller: self,
        filesManager: filesManager
    )

    private let errorLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.text = "no_preview_avalable".localized
        label.isHidden = true
        label.textColor = .textColor
        label.font = .systemFont(ofSize: 12)
        return label
    }()

    init(
        file: FileType,
        shouldShowDownloadButton: Bool,
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
        addWebView()
        showSpinner()
        title = file.name
        do {
            try load()
        } catch {
            Logger.logError("error previewing file: \(error)")
            // todo - exact error should be surfaced to user?
            errorLabel.isHidden = false
            hideSpinner()
        }
    }

    private func setupNavigationBar() {
        guard shouldShowDownloadButton else { return }
        navigationItem.rightBarButtonItem = NavigationBarItemsView(
            with: [
                NavigationBarItemsView.Input(
                    image: UIImage(named: "download")?.tinted(.gray),
                    title: "save".localized,
                    accessibilityId: "aid-save-attachment-to-device",
                    onTap: { [weak self] in self?.downloadAttachment() }
                )
            ]
        )
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
}

private extension AttachmentViewController {

    private func load() throws {
        guard let url = URL(string: "data:\(file.name.mimeType);base64,\(file.data.base64EncodedString())") else {
            throw AppErr.general("Could not produce a data URL to preview this file")
        }
        webView.load(URLRequest(url: url))
    }

    private func addWebView() {
        webView.backgroundColor = .backgroundColor
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(webView)
        webView.addSubview(errorLabel)

        NSLayoutConstraint.activate([
            webView.leftAnchor.constraint(equalTo: view.leftAnchor),
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.rightAnchor.constraint(equalTo: view.rightAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            errorLabel.leftAnchor.constraint(equalTo: webView.leftAnchor),
            errorLabel.topAnchor.constraint(equalTo: webView.topAnchor),
            errorLabel.rightAnchor.constraint(equalTo: webView.rightAnchor),
            errorLabel.bottomAnchor.constraint(equalTo: webView.bottomAnchor)
        ])
    }
}
