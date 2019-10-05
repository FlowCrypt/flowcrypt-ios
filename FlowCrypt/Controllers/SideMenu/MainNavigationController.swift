//
//  MainNavigationController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 04.10.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import UIKit

final class MainNavigationController: UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
}

extension UINavigationController {
    func setup() {
        navigationItem.backBarButtonItem = UIBarButtonItem().then { $0.title = "" }
        navigationBar.do {
            $0.barTintColor = .main
            $0.tintColor = .white
            $0.titleTextAttributes = [.foregroundColor: UIColor.white]
        }
    }
}
