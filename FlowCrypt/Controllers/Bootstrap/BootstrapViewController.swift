//
//  BootstrapViewController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 29/01/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import UIKit

final class BootstrapViewController: UIViewController {
    let imap = Imap.shared
    var completion: ((Error?) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .backgroundColor
        let activityIndicator = UIActivityIndicatorView(style: .gray)
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)
        activityIndicator.center = view.center
    }
}
