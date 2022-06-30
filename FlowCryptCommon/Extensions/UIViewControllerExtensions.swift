//
//  UIViewControllerExtension.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 8/20/19.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Toast
import UIKit
import MBProgressHUD

public typealias ShowToastCompletion = (Bool) -> Void

public extension UIViewController {
    /// Showing toast on root controller
    ///
    /// - Parameters:
    ///   - message: Message to be shown
    ///   - title: Title for the toast
    ///   - duration: Toast presented duration. Default is 3.0
    ///   - position: Bottom by default. Can be top, center, bottom.
    ///   - completion: Notify when toast dissapeared
    @MainActor
    func showToast(
        _ message: String,
        title: String? = nil,
        duration: TimeInterval = 3.0,
        position: ToastPosition = .bottom,
        completion: ShowToastCompletion? = nil
    ) {
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

public extension UIViewController {
    @MainActor
    func showAlert(title: String? = "error".localized, message: String, onOk: (() -> Void)? = nil) {
        self.view.hideAllToasts()
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
        self.present(alert, animated: true, completion: nil)
    }

    @MainActor
    func showAsyncAlert(title: String? = "error".localized, message: String) async throws {
        return try await withCheckedThrowingContinuation { (continuation) in
            showAlert(title: title, message: message, onOk: {
                return continuation.resume()
            })
        }
    }

    @MainActor
    func showRetryAlert(
        title: String? = "error".localized,
        message: String,
        cancelActionTitle: String = "cancel".localized,
        onRetry: ((UIAlertAction) -> Void)?,
        onCancel: ((UIAlertAction) -> Void)? = nil
    ) {
        self.view.hideAllToasts()
        hideSpinner()
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        let retry = UIAlertAction(
            title: "retry_title".localized,
            style: .cancel,
            handler: onRetry
        )
        let cancel = UIAlertAction(
            title: cancelActionTitle,
            style: .default,
            handler: onCancel)
        alert.addAction(retry)
        alert.addAction(cancel)
        present(alert, animated: true, completion: nil)
    }

    func keyboardHeight(from notification: Notification) -> CGFloat {
        (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height ?? 0
    }
}

public extension UINavigationController {
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

// MARK: - MBProgressHUD
public extension UIViewController {
    var currentProgressHUD: MBProgressHUD {
        MBProgressHUD.forView(view) ?? MBProgressHUD.showAdded(to: view, animated: true)
    }

    @MainActor
    func showSpinner(_ message: String = "loading_title".localized, isUserInteractionEnabled: Bool = false) {
        guard self.view.subviews.first(where: { $0 is MBProgressHUD }) == nil else {
            // hud is already shown
            return
        }
        self.view.isUserInteractionEnabled = isUserInteractionEnabled

        let spinner = MBProgressHUD.showAdded(to: self.view, animated: true)
        spinner.label.text = message
        spinner.isUserInteractionEnabled = isUserInteractionEnabled
        spinner.accessibilityIdentifier = "loadingSpinner"
    }

    @MainActor
    func updateSpinner(
        label: String = "compose_uploading".localized,
        progress: Float? = nil,
        systemImageName: String? = nil
    ) {
        if let progress = progress {
            if progress >= 1, let imageName = systemImageName {
                self.updateSpinner(
                    label: "compose_sent".localized,
                    systemImageName: imageName)
            } else {
                self.showProgressHUD(progress: progress, label: label)
            }
        } else {
            showIndeterminateHUD(with: label)
        }
    }

    @MainActor
    func hideSpinner() {
        let subviews = self.view.subviews.compactMap { $0 as? MBProgressHUD }
        for subview in subviews {
            subview.hide(animated: true)
        }
        self.view.isUserInteractionEnabled = true
    }

    @MainActor
    func showProgressHUD(progress: Float, label: String) {
        let percent = Int(progress * 100)
        currentProgressHUD.label.text = "\(label) \(percent)%"
        currentProgressHUD.progress = progress
        currentProgressHUD.mode = .annularDeterminate
    }

    @MainActor
    func showProgressHUDWithCustomImage(imageName: String, label: String) {
        let configuration = UIImage.SymbolConfiguration(pointSize: 36)
        let imageView = UIImageView(image: .init(systemName: imageName, withConfiguration: configuration))
        currentProgressHUD.minSize = CGSize(width: 150, height: 90)
        currentProgressHUD.customView = imageView
        currentProgressHUD.mode = .customView
        currentProgressHUD.label.text = label
    }

    @MainActor
    func showIndeterminateHUD(with title: String) {
        self.currentProgressHUD.mode = .indeterminate
        self.currentProgressHUD.label.text = title
    }
}
