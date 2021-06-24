//
//  BootstrapViewController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 29/01/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import UIKit

/**
 * View controller with activity indicator which is presented before all AppStartup activity finished (setup Core, migration of the DB...)
 */
final class BootstrapViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .backgroundColor
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)
        activityIndicator.center = view.center
    }
}
