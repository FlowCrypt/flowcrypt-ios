//
//  SetupStyle.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 29.10.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import UIKit

enum SetupStyle {
    static let title = "setup_title".localized.attributed(.bold(35), color: .black, alignment: .center)
    static let passPhrasePlaceholder = "setup_enter".localized.attributed(.bold(16), color: .lightGray, alignment: .center)
    static let useAnotherAccountTitle = "setup_use_another".localized.attributed(.regular(15), color: .blueColor, alignment: .center)
    static var subtitleStyle: (String) -> NSAttributedString {
        return {
            $0.attributed(.regular(17))
        }
    }

    static let titleInset = UIEdgeInsets(top: 92, left: 16, bottom: 20, right: 16)
    static let subTitleInset = UIEdgeInsets(top: 0, left: 16, bottom: 60, right: 16)
    static let buttonInsets = UIEdgeInsets(top: 80, left: 24, bottom: 8, right: 24)
    static let optionalBbuttonInsets = UIEdgeInsets(top: 0, left: 24, bottom: 8, right: 24)
    static let dividerInsets = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
}
