//
//  GlobalRouter.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 9/13/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import UIKit

protocol GlobalRouterType {
    func proceedAfterLogOut()
}

struct GlobalRouter: GlobalRouterType {
    func proceedAfterLogOut() {
        guard let delegate = (UIApplication.shared.delegate as? AppDelegate) else { assertionFailure(); return }
        delegate.window = delegate.assembley.setupWindow()
    }
}
