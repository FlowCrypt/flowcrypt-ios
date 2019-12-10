//
//  KeySettingsViewController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12/9/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import UIKit

final class KeySettingsViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let keys = DataManager.shared.keys() else { return }
        print(keys)
        Core.shared.parseKeys(armoredOrBinary: <#T##Data#>)
        
    }
}
