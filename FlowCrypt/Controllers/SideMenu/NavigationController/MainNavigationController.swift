//
//  MainNavigationController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 04.10.2019.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptUI

final class MainNavigationController: ASDKNavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        delegate = self
    }
}

/**
 * Default  styled UINavigationController for the app
 */
extension MainNavigationController: UINavigationControllerDelegate {
    func navigationController(_: UINavigationController, willShow viewController: UIViewController, animated _: Bool) {
        viewController.navigationItem.hidesBackButton = true
        navigationItem.hidesBackButton = true

        guard shouldShowBackButton(for: viewController) else {
            viewController.navigationItem.leftBarButtonItem = nil
            return
        }

        viewController.navigationItem.leftBarButtonItem = .defaultBackButton()
    }

    func navigationController(_: UINavigationController, didShow viewController: UIViewController, animated _: Bool) {
        guard shouldShowBackButton(for: viewController) else { return }
        viewController.navigationItem.leftBarButtonItem = .defaultBackButton { [weak self] in
            guard let self else { return }
            if let viewController = self.viewControllers.compactMap({ $0 as? NavigationChildController }).last {
                viewController.handleBackButtonTap()
            } else {
                self.popViewController(animated: true)
            }
        }
    }

    private func shouldShowBackButton(for viewController: UIViewController) -> Bool {
        guard viewControllers.firstIndex(of: viewController) != 0 else {
            return false
        }

        return (viewController as? NavigationChildController)?.shouldShowBackButton ?? true
    }
}

extension UINavigationController {
    func setup() {
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
        navigationItem.backBarButtonItem = UIBarButtonItem()
            .then { $0.title = "" }
        navigationBar.backItem?.title = ""

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .main
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactScrollEdgeAppearance = appearance

        navigationBar.do {
            $0.barTintColor = .main
            $0.tintColor = .white
            $0.titleTextAttributes = [.foregroundColor: UIColor.white]
        }
    }
}

extension UIBarButtonItem {
    static func defaultBackButton(with action: (() -> Void)? = nil) -> NavigationBarActionButton {
        NavigationBarActionButton(
            imageSystemName: "arrow.backward",
            action: action,
            accessibilityIdentifier: "aid-back-button"
        )
    }
}
