//
//  UIViewControllerExtension.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 8/20/19.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Toast
import UIKit

typealias ShowToastCompletion = (Bool) -> Void

extension UIViewController {
    /// Showing toast on root controller
    ///
    /// - Parameters:
    ///   - message: Message to be shown
    ///   - title: Title for the toast
    ///   - duration: Toast presented duration. Default is 3.0
    ///   - position: Bottom by default. Can be top, center, bottom.
    ///   - completion: Notify when toast dissapeared
    func showToast(
        _ message: String,
        title: String? = nil,
        duration: TimeInterval = 3.0,
        position: ToastPosition = .bottom,
        completion: ShowToastCompletion? = nil
    ) {
        DispatchQueue.main.async {
            guard let view = UIApplication.shared.keyWindow?.rootViewController?.view else {
                assertionFailure("Key window hasn't rootViewController")
                return
            }
            view.hideAllToasts()
            view.endEditing(true)

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
}

extension UIViewController {
    private func errorToUserFriendlyString(error: Error, title: String) -> String? {
        // todo - more intelligent handling of HttpErr
        do {
            throw error
        } catch let AppErr.user(userErr) {
            // if this is AppErr.user, show only the content of the message to the user, not info about the exception
            return "\(title)\n\n\(userErr)"
        } catch AppErr.silentAbort { // don't show any alert
            return nil
        } catch {
            return "\(title)\n\n\(error)"
        }
    }

    func showAlert(error: Error, message: String, onOk: (() -> Void)? = nil) {
        guard let formatted = errorToUserFriendlyString(error: error, title: message) else {
            hideSpinner()
            onOk?()
            return // silent abort
        }
        showAlert(message: formatted, onOk: onOk)
    }

    func showAlert(title: String? = "error".localized, message: String, onOk: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            self.view.hideAllToasts()
            self.hideSpinner()
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .destructive) { _ in onOk?() })
            self.present(alert, animated: true, completion: nil)
        }
    }

    func showRetryAlert(
        title: String? = "error".localized,
        message: String,
        onRetry: (() -> Void)? = nil,
        onOk: (() -> Void)? = nil
    ) {
        DispatchQueue.main.async {
            self.view.hideAllToasts()
            self.hideSpinner()
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Retry", style: .cancel) { _ in onRetry?() })
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in onOk?() })
            self.present(alert, animated: true, completion: nil)
        }
    }

    func keyboardHeight(from notification: Notification) -> CGFloat {
        (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height ?? 0
    }
}

extension UINavigationController {
    func pushViewController(viewController: UIViewController, animated: Bool, completion: @escaping () -> Void) {
        pushViewController(viewController, animated: animated)

        if let coordinator = transitionCoordinator, animated {
            coordinator.animate(alongsideTransition: nil) { _ in
                completion()
            }
        } else {
            completion()
        }
    }

    func popViewController(animated: Bool, completion: @escaping () -> Void) {
        popViewController(animated: animated)

        if let coordinator = transitionCoordinator, animated {
            coordinator.animate(alongsideTransition: nil) { _ in
                completion()
            }
        } else {
            completion()
        }
    }
}
