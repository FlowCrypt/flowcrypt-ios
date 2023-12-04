//
//  UIViewControllerExtensions.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 8/20/19.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import ProgressHUD
import Toast
import UIKit

// MARK: - Toast
public typealias ShowToastCompletion = (Bool) -> Void
public extension UIViewController {
    /// Showing toast on root controller
    ///
    /// - Parameters:
    ///   - message: Message to be shown
    ///   - title: Title for the toast
    ///   - duration: Toast presented duration. Default is 3.0
    ///   - position: Bottom by default. Can be top, center, bottom.
    ///   - shouldHideKeyboard: True by default. Hide keyboard when toast is presented
    ///   - completion: Notify when toast dissappeared
    @MainActor
    func showToast(
        _ message: String,
        title: String? = nil,
        duration: TimeInterval = 3.0,
        position: ToastPosition = .bottom,
        shouldHideKeyboard: Bool = true,
        completion: ShowToastCompletion? = nil,
        view: UIView? = nil,
        maxHeightPercentage: CGFloat? = nil
    ) {
        guard let view = view ?? UIApplication.shared.currentWindow?.rootViewController?.view else {
            assertionFailure("Key window hasn't rootViewController")
            return
        }
        view.hideAllToasts()

        if shouldHideKeyboard {
            view.endEditing(true)
        }

        if let maxHeightPercentage {
            ToastManager.shared.style.maxHeightPercentage = maxHeightPercentage
        }

        view.makeToast(
            message,
            duration: duration,
            position: position,
            title: title,
            completion: completion
        )

        ToastManager.shared.isTapToDismissEnabled = true
    }
}

// MARK: - Alerts
public extension UIViewController {
    @MainActor
    func showAlert(title: String? = "error".localized, message: String, onOk: (() -> Void)? = nil) {
        view.hideAllToasts()
        hideSpinner()
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        let ok = UIAlertAction(
            title: "ok".localized,
            style: .destructive
        ) { _ in onOk?() }
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }

    @MainActor
    func showAsyncAlert(title: String? = "error".localized, message: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            showAlert(title: title, message: message) {
                return continuation.resume()
            }
        }
    }

    @MainActor
    func showAlertWithAction(
        title: String?,
        message: String?,
        cancelButtonTitle: String = "cancel".localized,
        actionButtonTitle: String,
        actionAccessibilityIdentifier: String? = "aid-confirm-button",
        actionStyle: UIAlertAction.Style = .default,
        onAction: ((UIAlertAction) -> Void)?,
        onCancel: ((UIAlertAction) -> Void)? = nil
    ) {
        view.hideAllToasts()
        hideSpinner()
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        let action = UIAlertAction(
            title: actionButtonTitle,
            style: actionStyle,
            handler: onAction
        )
        action.accessibilityIdentifier = actionAccessibilityIdentifier
        let cancel = UIAlertAction(
            title: cancelButtonTitle,
            style: .cancel,
            handler: onCancel
        )
        cancel.accessibilityIdentifier = "aid-cancel-button"
        alert.addAction(action)
        alert.addAction(cancel)
        present(alert, animated: true, completion: nil)
    }

    @MainActor
    func showPermanentDeleteThreadAlert(
        threadCount: Int,
        onAction: ((UIAlertAction) -> Void)?,
        onCancel: ((UIAlertAction) -> Void)? = nil
    ) {
        showAlertWithAction(
            title: "message_permanently_delete_title".localized,
            message: "message_permanently_delete".localizeWithArguments("%@ thread(s)".localizePluralsWithArguments(threadCount)),
            actionButtonTitle: "delete".localized,
            actionStyle: .destructive,
            onAction: onAction,
            onCancel: onCancel
        )
    }

    @MainActor
    func showRetryAlert(
        title: String? = "error".localized,
        message: String,
        cancelButtonTitle: String = "cancel".localized,
        onRetry: ((UIAlertAction) -> Void)?,
        onCancel: ((UIAlertAction) -> Void)? = nil
    ) {
        showAlertWithAction(
            title: title,
            message: message,
            cancelButtonTitle: cancelButtonTitle,
            actionButtonTitle: "retry_title".localized,
            onAction: onRetry,
            onCancel: onCancel
        )
    }

    @MainActor
    func showConfirmAlert(message: String, onConfirm: ((UIAlertAction) -> Void)?) {
        showAlertWithAction(
            title: "warning".localized,
            message: message,
            actionButtonTitle: "confirm".localized,
            onAction: onConfirm
        )
    }

    func keyboardHeight(from notification: Notification) -> CGFloat {
        (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height ?? 0
    }
}

// MARK: - Navigation
public extension UINavigationController {
    func pushViewController(viewController: UIViewController, animated: Bool, completion: @escaping () -> Void) {
        pushViewController(viewController, animated: animated)

        if let transitionCoordinator, animated {
            transitionCoordinator.animate(alongsideTransition: nil) { _ in
                completion()
            }
        } else {
            completion()
        }
    }

    func popViewController(animated: Bool, completion: @escaping () -> Void) {
        popViewController(animated: animated)

        if let transitionCoordinator, animated {
            transitionCoordinator.animate(alongsideTransition: nil) { _ in
                completion()
            }
        } else {
            completion()
        }
    }
}

// MARK: - ProgressHUD
public extension UIViewController {
    func showSpinner(_ message: String = "loading_title".localized, isUserInteractionEnabled: Bool = false) {
        ProgressHUD.animate(message, interaction: isUserInteractionEnabled)
    }

    func showSpinnerWithProgress(_ message: String = "loading_title".localized, progress: Float) {
        ProgressHUD.progress(message, CGFloat(progress))
    }

    func hideSpinner() {
        ProgressHUD.dismiss()
    }
}
