//
//  AlertsFactory.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 17.06.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptCommon
import FlowCryptUI
import UIKit

class AlertsFactory {
    typealias PassPhraseCompletion = (String) -> Void
    typealias CancelCompletion = () -> Void

    let encryptedStorage: EncryptedStorageType

    init(encryptedStorage: EncryptedStorageType) {
        self.encryptedStorage = encryptedStorage
    }

    private var textFieldDelegate: UITextFieldDelegate?

    func passphraseCheckFailed() {
        guard var activeUser = try? encryptedStorage.activeUser else {
            return
        }
        activeUser.failedPassPhraseAttempts = (activeUser.failedPassPhraseAttempts ?? 0) + 1
        activeUser.lastUnsuccessfulPassPhraseAttempt = Date()
        try? encryptedStorage.saveActiveUser(with: activeUser)
    }

    func passphraseCheckSucceed() {
        guard var activeUser = try? encryptedStorage.activeUser else {
            return
        }
        activeUser.failedPassPhraseAttempts = nil
        activeUser.lastUnsuccessfulPassPhraseAttempt = nil
        try? encryptedStorage.saveActiveUser(with: activeUser)
    }

    func makePassPhraseAlert(
        viewController: UIViewController,
        title: String = "setup_enter_pass_phrase".localized,
        onCancel: @escaping CancelCompletion,
        onCompletion: @escaping PassPhraseCompletion
    ) {
        guard var activeUser = try? encryptedStorage.activeUser else {
            return
        }
        let alertNode = PassPhraseAlertNode(
            failedPassPhraseAttempts: activeUser.failedPassPhraseAttempts,
            lastUnsuccessfulPassPhraseAttempt: activeUser.lastUnsuccessfulPassPhraseAttempt,
            title: title,
            message: nil
        )
        alertNode.onOkay = { passPhrase in
            guard let passPhrase, passPhrase.isNotEmpty
            else {
                return
            }
            viewController.dismiss(animated: true) {
                onCompletion(passPhrase)
            }
        }
        alertNode.onCancel = {
            viewController.dismiss(animated: true)
            onCancel()
        }
        alertNode.resetFailedPassphraseAttempts = {
            activeUser.failedPassPhraseAttempts = 0
            try? self.encryptedStorage.saveActiveUser(with: activeUser)
        }
        let alertViewController = ASDKViewController(node: alertNode)
        alertViewController.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        alertViewController.modalTransitionStyle = UIModalTransitionStyle.crossDissolve

        viewController.present(alertViewController, animated: true, completion: nil)
    }

    func makeCustomAlert(
        viewController: UIViewController,
        title: String = "error".localized,
        message: String
    ) {
        let alertNode = CustomAlertNode(
            title: title,
            message: message
        )
        alertNode.onOkay = {
            viewController.dismiss(animated: true)
        }
        let alertViewController = ASDKViewController(node: alertNode)
        alertViewController.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        alertViewController.modalTransitionStyle = UIModalTransitionStyle.crossDissolve

        viewController.present(alertViewController, animated: true, completion: nil)
    }
}

class SubmitOnPasteTextFieldDelegate: NSObject, UITextFieldDelegate {
    let onSubmit: (String) -> Void

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
