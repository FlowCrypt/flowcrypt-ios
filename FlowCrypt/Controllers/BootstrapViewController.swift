//
//  BootstrapViewController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 29/01/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import UIKit
import Promises

final class BootstrapViewController: UIViewController {
    let imap = Imap.shared
    var completion: ((Error?) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
 
        do {
            _ = try await(URLSession.shared.call("http://google.com"))
            self.imap.renewSession()
                .then(on: .main, {
                    self.completion?(nil)
                })
        } catch {
            self.completion?(AppErr.connection)
        }
    }
}
