//
//  UIViewControllerExtension.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 8/20/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import UIKit
import Toast

enum ToastPosition: String {
    case bottom, top, center

    var value: String {
        switch self {
        case .bottom: return CSToastPositionBottom
        case .center: return CSToastPositionCenter
        case .top:    return CSToastPositionTop
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
    ///   - duration: Default value 0.3
    ///   - position: Bottom by default. Can be top, center, bottom.
    ///   - completion: Notify when toast dissapeared
    func showToast(
        _ message: String,
        title: String = "",
        duration: TimeInterval = 0.3,
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
                image: UIImage(),
                style: CSToastStyle.init(defaultStyle: ()),
                completion: completion
            )

            CSToastManager.setTapToDismissEnabled(true)
        }
    }
}
