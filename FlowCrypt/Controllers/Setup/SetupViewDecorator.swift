//
//  SetupStyle.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 29.10.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import UIKit
import FlowCryptUI
import FlowCryptCommon

protocol SetupViewDecoratorType {
    var title: NSAttributedString { get }
    var useAnotherAccountTitle: NSAttributedString { get }
    var titleInset: UIEdgeInsets { get }
    var subTitleInset: UIEdgeInsets { get }
    var buttonInsets: UIEdgeInsets { get }
    var optionalButtonInsets: UIEdgeInsets { get }
    var textFieldStyle: TextFieldCellNode.Input { get }

    func buttonTitle(for state: SetupViewController.State) -> NSAttributedString
    func subtitle(for state: SetupViewController.State) -> NSAttributedString
}

struct SetupViewDecorator: SetupViewDecoratorType {
    let textFieldStyle = SetupCommonStyle.passPhraseTextFieldStyle

    var title: NSAttributedString {
        "setup_title".localized.attributed(.bold(35), color: .mainTextColor, alignment: .center)
    }
    var useAnotherAccountTitle: NSAttributedString {
        "setup_use_another".localized.attributed(
            .regular(15),
            color: UIColor.colorFor(darkStyle: .black, lightStyle: .blueColor),
            alignment: .center
        )
    }

    let titleInset = UIEdgeInsets(top: 92, left: 16, bottom: 20, right: 16)
    let subTitleInset = UIEdgeInsets(top: 0, left: 16, bottom: 60, right: 16)
    let buttonInsets = UIEdgeInsets(top: 80, left: 24, bottom: 8, right: 24)
    let optionalButtonInsets = UIEdgeInsets(top: 0, left: 24, bottom: 8, right: 24)

    func buttonTitle(for state: SetupViewController.State) -> NSAttributedString {
        let title: String
        switch state {
        case .createKey: title = "setup_create_key"
        default: title = "setup_load"
        }

        return title.localized.attributed(.regular(17), color: .white, alignment: .center)
    }
    func subtitle(for state: SetupViewController.State) -> NSAttributedString {
        let subtitle: String = {
            switch state {
            case let .fetchedEncrypted(keys):
                return "Found \(keys.count) key backup\(keys.count > 1 ? "s" : "")"
            case .createKey:
                return "setup_action_create_new_subtitle".localized
            default:
                return "setup_description".localized
            }
        }()

        return subtitle.attributed(.regular(17))
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
