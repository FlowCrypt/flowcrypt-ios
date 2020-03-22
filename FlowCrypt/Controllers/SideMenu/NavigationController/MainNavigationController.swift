//
//  MainNavigationController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 04.10.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptUI

final class MainNavigationController: ASNavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        delegate = self
    }
}

extension MainNavigationController: UINavigationControllerDelegate {
    func navigationController(_: UINavigationController, willShow viewController: UIViewController, animated _: Bool) {
        viewController.navigationItem.hidesBackButton = true
        navigationItem.hidesBackButton = true

        guard viewControllers.firstIndex(of: viewController) != 0 else { return }
        viewController.navigationItem.leftBarButtonItem = NavigationBarActionButton(UIImage(named: "arrow-left-c"), action: nil)
    }

    func navigationController(_: UINavigationController, didShow viewController: UIViewController, animated _: Bool) {
        guard viewControllers.firstIndex(of: viewController) != 0 else { return }
        let navigationButton = NavigationBarActionButton(UIImage(named: "arrow-left-c")) { [weak self] in
            guard let self = self else { return }
            if let viewController = self.viewControllers.compactMap({ $0 as? NavigationChildController }).last {
                viewController.handleBackButtonTap()
            } else {
                self.popViewController(animated: true)
            }
        }

        viewController.navigationItem.leftBarButtonItem = navigationButton
    }
}

extension UINavigationController {
    func setup() {
        navigationItem.backBarButtonItem = UIBarButtonItem()
            .then { $0.title = "" }
        navigationBar.backItem?.title = ""
        navigationBar.do {
            $0.barTintColor = .main
            $0.tintColor = .white
            $0.titleTextAttributes = [.foregroundColor: UIColor.white]
        }
    }
}
