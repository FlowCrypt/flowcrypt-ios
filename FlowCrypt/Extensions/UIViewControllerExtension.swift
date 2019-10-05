//
//  UIViewControllerExtension.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 8/20/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import MBProgressHUD
import Promises
import RxCocoa
import RxSwift
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
    /// Observable keyboard height from willShow and willHide notifications
    /// deliver signals on main queue.
    var keyboardHeight: Observable<CGFloat> {
        let willShowNotification = NotificationCenter.default.rx
            .notification(UIResponder.keyboardWillShowNotification)
            .map { notification in
                (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.height ?? 0
            }
        let willHideNotification = NotificationCenter.default.rx
            .notification(UIResponder.keyboardWillHideNotification)
            .map { _ in CGFloat(0) }

        return Observable.from([willShowNotification, willHideNotification])
            .merge()
            .observeOn(MainScheduler.instance)
            .takeUntil(rx.deallocated)
    }
}

extension UIViewController {
    var safeAreaWindowInsets: UIEdgeInsets {
        return UIApplication.shared.keyWindow?.safeAreaInsets ?? .zero
    }

    var statusBarHeight: CGFloat {
        return UIApplication.shared.statusBarFrame.height
    }

    private func errorToUserFriendlyString(error: Error, title: String) -> String? {
        // todo - more intelligent handling of HttpErr
        do {
            throw error
        } catch let AppErr.user(userErr) { // if this is AppErr.user, show only the content of the message to the user, not info about the exception
            return "\(title)\n\n\(userErr)"
        } catch AppErr.silentAbort { // don't show any alert
            return nil
        } catch {
            return "\(title)\n\n\(error)"
        }
    }

    func showAlert(error: Error, message: String, onOk: (() -> Void)? = nil) {
        guard let formatted = self.errorToUserFriendlyString(error: error, title: message) else {
            hideSpinner()
            onOk?()
            return // silent abort
        }
        showAlert(message: formatted, onOk: onOk)
    }

    func showAlert(message: String, onOk: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            self.view.hideAllToasts()
            self.hideSpinner()
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .destructive) { _ in onOk?() })
            self.present(alert, animated: true, completion: nil)
        }
    }

    func showSpinner(_ message: String = Language.loading, isUserInteractionEnabled: Bool = false) {
        DispatchQueue.main.async {
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
        return Promise<Void> { [weak self] resolve, _ in
            guard let self = self else { throw AppErr.nilSelf }
            do {
                _ = try await(promise)
                resolve(())
            } catch {
                DispatchQueue.main.async {
                    self.showAlert(error: error, message: msg, onOk: { resolve(()) })
                }
            }
        }
    }

    func awaitUserPassPhraseEntry(title: String) -> Promise<String?> {
        return Promise<String?>(on: .main) { [weak self] resolve, _ in
            guard let self = self else { throw AppErr.nilSelf }
            let alert = UIAlertController(title: "Pass Phrase", message: title, preferredStyle: .alert)
            alert.addTextField { textField in
                textField.isSecureTextEntry = true
            }
            alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { _ in
                resolve(nil)
            }))
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] _ in
                resolve(alert?.textFields?[0].text)
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }

    func awaitUserConfirmation(title: String) -> Promise<Bool> {
        return Promise<Bool>(on: .main) { [weak self] resolve, _ in
            guard let self = self else { throw AppErr.nilSelf }
            let alert = UIAlertController(title: "Are you sure?", message: title, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { _ in resolve(false) }))
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in resolve(true) }))
            self.present(alert, animated: true, completion: nil)
        }
    }
}
