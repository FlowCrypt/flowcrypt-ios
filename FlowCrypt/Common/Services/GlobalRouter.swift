
//
//  GlobalRouter.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 9/13/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import UIKit

protocol GlobalRouterType {
    func reset()
}

struct GlobalRouter: GlobalRouterType {
    func reset() {
        guard let delegate = (UIApplication.shared.delegate as? AppDelegate) else { assertionFailure(); return }
        delegate.window = delegate.assembley.setupWindow()
    }
}
