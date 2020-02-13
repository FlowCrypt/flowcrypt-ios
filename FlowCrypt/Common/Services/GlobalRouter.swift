
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
        let application = UIApplication.shared
        guard let delegate = (application.delegate as? AppDelegate) else {
            assertionFailure("missing AppDelegate in GlobalRouter.reset()");
            return;
        }
        AppStartup().initializeApp(window: delegate.window)
    }
}
