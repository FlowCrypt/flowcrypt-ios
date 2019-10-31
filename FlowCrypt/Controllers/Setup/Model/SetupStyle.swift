//
//  SetupStyle.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 29.10.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation

enum SetupStyle {
    static let title = "setup_title".localized.attributed(.bold(35), color: .black, alignment: .center)
    static let passPrasePlaceholder = "setup_enter".localized.attributed(.bold(16), color: .darkGray, alignment: .center)
    static let useAnotherAccountTitle = "setup_use_another".localized.attributed(.regular(15), color: .blue, alignment: .center)
    static var subtitleStyle: (String) -> NSAttributedString {
        return {
            $0.attributed(.regular(17))
        }
    }
}
