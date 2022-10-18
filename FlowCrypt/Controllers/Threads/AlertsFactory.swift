//
//  AlertsFactory.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 17.06.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit
import FlowCryptCommon

class AlertsFactory {
    typealias PassPhraseCompletion = ((String) -> Void)
    typealias CancelCompletion = (() -> Void)

    private var textFieldDelegate: UITextFieldDelegate?

    func makePassPhraseAlert(
        title: String = "setup_enter_pass_phrase".localized,
        onCancel: @escaping CancelCompletion,
        onCompletion: @escaping PassPhraseCompletion
    ) -> UIAlertController {
        let alert = UIAlertController(
            title: title,
            message: nil,
            preferredStyle: .alert
        )

        textFieldDelegate = SubmitOnPasteTextFieldDelegate(onSubmit: { passPhrase in
            alert.dismiss(animated: true, completion: {
                onCompletion(passPhrase)
            })
        })

        alert.addTextField { [weak self] tf in
            tf.isSecureTextEntry = true
            tf.delegate = self?.textFieldDelegate
            tf.accessibilityIdentifier = "aid-message-passphrase-textfield"
        }
        let saveAction = UIAlertAction(
            title: "ok".localized,
            style: .default
        ) { _ in
            guard let textField = alert.textFields?.first,
                  let passPhrase = textField.text,
                  passPhrase.isNotEmpty
            else {
                alert.dismiss(animated: true, completion: nil)
                return
            }

            alert.dismiss(animated: true) {
                onCompletion(passPhrase)
            }
        }
        let cancelAction = UIAlertAction(
            title: "cancel".localized,
            style: .destructive
        ) { _ in
            alert.dismiss(animated: true) {
                onCancel()
            }
        }

        alert.addAction(cancelAction)
        alert.addAction(saveAction)

        return alert
    }
}

class SubmitOnPasteTextFieldDelegate: NSObject, UITextFieldDelegate {
    let onSubmit: ((String) -> Void)

    init(onSubmit: @escaping ((String) -> Void)) {
        self.onSubmit = onSubmit

        super.init()
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let isTextFieldEmpty = textField.text?.isEmpty ?? true
        let isPaste = isTextFieldEmpty && string.count > 1

        if isPaste { onSubmit(string) }

        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let text = textField.text, text.isNotEmpty {
            onSubmit(text)
        }
        return true
    }
}
