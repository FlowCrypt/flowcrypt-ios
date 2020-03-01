//
//  SetupStyle.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 29.10.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import UIKit
import FlowCryptUI

protocol SetupDecoratorType {
    var title: NSAttributedString { get }
    var useAnotherAccountTitle: NSAttributedString { get }
    var titleInset: UIEdgeInsets { get }
    var subTitleInset: UIEdgeInsets { get }
    var buttonInsets: UIEdgeInsets { get }
    var optionalButtonInsets: UIEdgeInsets { get }
    var textFieldStyle: TextFieldCellNode.Input { get }
    var subtitleStyle: (String) -> NSAttributedString { get }
    func titleForAction(button: SetupViewController.SetupAction) -> NSAttributedString
}

struct SetupDecorator: SetupDecoratorType {
    let title = "setup_title".localized.attributed(.bold(35), color: .black, alignment: .center)
    let useAnotherAccountTitle = "setup_use_another".localized.attributed(.regular(15), color: .blueColor, alignment: .center)
    var subtitleStyle: (String) -> NSAttributedString {
        { $0.attributed(.regular(17)) }
    }

    let titleInset = UIEdgeInsets(top: 92, left: 16, bottom: 20, right: 16)
    let subTitleInset = UIEdgeInsets(top: 0, left: 16, bottom: 60, right: 16)
    let buttonInsets = UIEdgeInsets(top: 80, left: 24, bottom: 8, right: 24)
    let optionalButtonInsets = UIEdgeInsets(top: 0, left: 24, bottom: 8, right: 24)

    let textFieldStyle = SetupCommonStyle.passPhraseTextFieldStyle

    func titleForAction(button: SetupViewController.SetupAction) -> NSAttributedString {
        let title: String
        switch button {
        case .createKey: title = "setup_create_key"
        case .recoverKey: title = "setup_load"
        }
        return title.localized.attributed(.regular(17), color: .white, alignment: .center)
    }
}

enum SetupCommonStyle {
    static let passPhraseTextFieldStyle: TextFieldCellNode.Input = TextFieldCellNode.Input(
        placeholder: "setup_enter".localized.attributed(.bold(16), color: .lightGray, alignment: .center),
        isSecureTextEntry: true,
        textInsets: 0,
        textAlignment: .center,
        insets: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    )
}
