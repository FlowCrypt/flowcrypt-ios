//
//  AlertsFactory.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 17.06.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit
import FlowCryptCommon

enum AlertsFactory {
    typealias PassPhraseCompletion = ((String) -> Void)
    typealias CancelCompletion = (() -> Void)

    static func makePassPhraseAlert(
        title: String = "setup_enter_pass_phrase".localized,
        onCancel: @escaping CancelCompletion,
        onCompletion: @escaping PassPhraseCompletion
    ) -> UIAlertController {
        let alert = UIAlertController(
            title: title,
            message: nil,
            preferredStyle: .alert
        )

        alert.addTextField { tf in
            tf.isSecureTextEntry = true
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
