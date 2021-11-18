//
//  InvalidStorageViewController.swift
//  FlowCrypt
//
//  Created by  Ivan Ushakov on 24.10.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit

final class InvalidStorageViewController: UIViewController {
    private let error: Error
    private let encryptedStorage: EncryptedStorageType
    private let router: GlobalRouterType

    init(error: Error, encryptedStorage: EncryptedStorageType, router: GlobalRouterType) {
        self.error = error
        self.encryptedStorage = encryptedStorage
        self.router = router
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "invalid_storage_title".localized

        view.backgroundColor = .white

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "invalid_storage_text".localized
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 16)
        view.addSubview(label)

        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.text = error.localizedDescription
        view.addSubview(textView)

        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .red
        button.setTitle("invalid_storage_reset_button".localized, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        button.layer.cornerRadius = 5
        view.addSubview(button)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            label.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
            label.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),

            textView.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 10),
            textView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
            textView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
            textView.bottomAnchor.constraint(equalTo: button.topAnchor, constant: -10),

            button.heightAnchor.constraint(equalToConstant: 50),
            button.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
            button.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
            button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8)
        ])
    }

    @objc private func handleTap() {
        do {
            try encryptedStorage.reset()
            router.proceed()
        } catch {
            showAlert(message: "invalid_storage_reset_error".localized)
        }
    }
}
