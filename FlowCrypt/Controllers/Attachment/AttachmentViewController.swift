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
        saveAndStartDownload(file: file)
    }

    private func remove(file: FileType) {
        Task { [weak self] in
            do {
                try await filesManager.remove(file: file)
                self?.navigationController?.popViewController(animated: true)
            } catch let error {
                showAlert(
                    message: "could_not_remove_opened_attachment".localized + " (\(error.localizedDescription))"
                ) {
                    self?.navigationController?.popViewController(animated: true)
                }
            }
        }
    }

    private func saveAndStartDownload(file: FileType) {
        Task { [weak self] in
            do {
                let url = try await filesManager.save(file: file)
                self?.load(with: url)
            } catch let error {
                showAlert(
                    message: "could_not_open_an_attachment".localized + " (\(error.localizedDescription))"
                ) {
                    self?.navigationController?.popViewController(animated: true)
                }
            }
        }
    }

    private func setupNavigationBar() {
        guard shouldShowDownloadButton else { return }
        navigationItem.rightBarButtonItem = NavigationBarItemsView(
            with: [
                NavigationBarItemsView.Input(
                    image: UIImage(named: "download")?.tinted(.gray),
                    title: "save".localized,
                    onTap: { [weak self] in
                        guard let self = self else { return }
                        self.attachmentManager.download(self.file)
                    }
                )
            ]
        )
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

    private func load(with link: URL?) {
        guard let wrappedLink = link else {
            errorLabel.isHidden = false
            hideSpinner()
            return
        }
        webView.load(URLRequest(url: wrappedLink))
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

extension AttachmentViewController: NavigationChildController {
    func handleBackButtonTap() {
        remove(file: file)
    }
}
