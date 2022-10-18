//
//  ComposeViewController+Contacts.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 02/09/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit

extension ComposeViewController {
    func askForContactsPermission() {
        shouldEvaluateRecipientInput = false

        Task {
            do {
                try await router.askForContactsPermission(
                    for: .gmailLogin(self),
                    appContext: appContext
                )
                shouldEvaluateRecipientInput = true
                reload(sections: [.contacts])
            } catch {
                shouldEvaluateRecipientInput = true
                handleContactsPermissionError(error)
            }
        }
    }

    private func handleContactsPermissionError(_ error: Error) {
        guard let gmailUserError = error as? GoogleUserServiceError,
           case .userNotAllowedAllNeededScopes(let missingScopes, _) = gmailUserError
        else { return }

        let scopes = missingScopes.map(\.title).joined(separator: ", ")

        showAlertWithAction(
            title: "error".localized,
            message: "compose_missing_contacts_scopes".localizeWithArguments(scopes),
            cancelButtonTitle: "later".localized,
            actionButtonTitle: "allow".localized,
            onAction: { [weak self] _ in
                self?.askForContactsPermission()
            }
        )
    }
}
