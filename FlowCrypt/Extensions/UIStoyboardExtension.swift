//
//  UIStoyboardExtension.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 8/21/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import UIKit

extension UIStoryboard { 
    func instantiate<T>(_ viewController: T.Type) -> T {
        return instantiateViewController(withIdentifier: String(describing: viewController.self)) as! T
    }
}
