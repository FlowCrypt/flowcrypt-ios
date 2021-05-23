//
//  SetupStyle.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 29.10.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import FlowCryptCommon
import FlowCryptUI
import UIKit

struct SetupViewInsets {
    let titleInset = UIEdgeInsets(top: 92, left: 16, bottom: 20, right: 16)
    let subTitleInset = UIEdgeInsets(top: 0, left: 16, bottom: 60, right: 16)
    let buttonInsets = UIEdgeInsets(top: 80, left: 24, bottom: 8, right: 24)
    let optionalButtonInsets = UIEdgeInsets(top: 0, left: 24, bottom: 8, right: 24)
    let dividerInsets = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
}

enum SetupCommonStyle {
    static let passPhraseTextFieldStyle: TextFieldCellNode.Input = TextFieldCellNode.Input(
        placeholder: "setup_enter"
            .localized
            .attributed(
                .bold(16),
                color: .lightGray,
                alignment: .center
            ),
            isSecureTextEntry: true,
            textInsets: 0,
            textAlignment: .center,
            insets: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    )
}

struct SetupViewDecorator {
    let insets = SetupViewInsets()

    let textFieldStyle = SetupCommonStyle.passPhraseTextFieldStyle

    let title = "setup_title"
        .localized
        .attributed(
            .bold(35),
            color: .mainTextColor,
            alignment: .center
        )

    let buttonTitle = "setup_load"
        .localized
        .attributed(
            .regular(17),
            color: .white,
            alignment: .center
        )

    let useAnotherAccountTitle = "setup_use_another"
        .localized
        .attributed(
            .regular(15),
            color: UIColor.colorFor(
                darkStyle: .black,
                lightStyle: .blueColor
            ),
            alignment: .center
        )

    func subtitle(for state: SetupViewController.State) -> NSAttributedString {
        let subtitle: String = {
            switch state {
            case let .fetchedEncrypted(keys):
                return "Found \(keys.count) key backup\(keys.count > 1 ? "s" : "")"
            default:
                return "setup_description".localized
            }
        }()

        return subtitle.attributed(.regular(17))
    }
}
