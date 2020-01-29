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
        view.backgroundColor = .white

        // googleManager.restorePreviousSignIn() doesn't return error if session can't be restored.
        // should be reworked to have some failure callback and completion should be called after receiveing a new session
        // or after receiving error
        imap.renewSession()
        completion?(nil)
    }
}
