//
//  UIViewControllerExtension.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 8/20/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import MBProgressHUD
import Promises
import Toast
import UIKit

enum ToastPosition: String {
    case bottom, top, center

    var value: String {
        switch self {
        case .bottom: return CSToastPositionBottom
        case .center: return CSToastPositionCenter
        case .top: return CSToastPositionTop
        }
    }
}

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
                position: position.value,
                title: title,
                image: nil,
                style: CSToastStyle(defaultStyle: ()),
                completion: completion
            )

            CSToastManager.setTapToDismissEnabled(true)
        }
    }
}

extension UIViewController {
    var safeAreaWindowInsets: UIEdgeInsets {
        UIApplication.shared.keyWindow?.safeAreaInsets ?? .zero
    }

    var statusBarHeight: CGFloat {
        UIApplication.shared.statusBarFrame.height
    }

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

    func showAlert(title: String? = "Error", message: String, onOk: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            self.view.hideAllToasts()
            self.hideSpinner()
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .destructive) { _ in onOk?() })
            self.present(alert, animated: true, completion: nil)
        }
    }

    func showSpinner(_ message: String = "loading_title".localized, isUserInteractionEnabled: Bool = false) {
        DispatchQueue.main.async {
            guard self.view.subviews.first(where: { $0 is MBProgressHUD }) == nil else {
                // hud is already shown
                return
            }

            let spinner = MBProgressHUD.showAdded(to: self.view, animated: true)
            spinner.label.text = message
            spinner.isUserInteractionEnabled = isUserInteractionEnabled
        }
    }

    func hideSpinner() {
        DispatchQueue.main.async {
            self.view.subviews
                .compactMap { $0 as? MBProgressHUD }
                .forEach { $0.hide(animated: true) }
        }
    }

    func alertAndSkipOnRejection<T>(_ promise: Promise<T>, fail msg: String) -> Promise<Void> {
        Promise<Void> { [weak self] resolve, _ in
            guard let self = self else { throw AppErr.nilSelf }
            do {
                _ = try awaitPromise(promise)
                resolve(())
            } catch {
                DispatchQueue.main.async {
                    self.showAlert(error: error, message: msg, onOk: { resolve(()) })
                }
            }
        }
    }

    // TODO: - ANTON
    func awaitUserPassPhraseEntry(title: String) -> Promise<String?> {
        Promise<String?>(on: .main) { [weak self] resolve, _ in
            guard let self = self else { throw AppErr.nilSelf }
            let alert = UIAlertController(title: "Pass Phrase", message: title, preferredStyle: .alert)
            alert.addTextField { textField in
                textField.isSecureTextEntry = true
                textField.accessibilityLabel = "textField"
            }

            alert.addAction(UIAlertAction(title: "Cancel", style: .default) { _ in
                resolve(nil)
            })

            alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak alert] _ in
                resolve(alert?.textFields?[0].text)
            })
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
