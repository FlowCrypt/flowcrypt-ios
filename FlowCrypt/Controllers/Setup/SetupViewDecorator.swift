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
    let titleInset = UIEdgeInsets(top: 92, left: 16, bottom: 100, right: 16)
    let subTitleInset = UIEdgeInsets(top: 0, left: 16, bottom: 60, right: 16)
    let buttonInsets = UIEdgeInsets(top: 8, left: 24, bottom: 8, right: 24)
    let optionalButtonInsets = UIEdgeInsets(top: 0, left: 24, bottom: 8, right: 24)
    let dividerInsets = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
}

struct SetupViewDecorator {
    let insets = SetupViewInsets()

    let setupTitle = "setup_title"
        .localized
        .attributed(
            .bold(35),
            color: .mainTextColor,
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

    let passPhraseLostDescription = "create_pass_phrase_lost"
        .localized
        .attributed(
            .regular(16),
            color: .lightGray,
            alignment: .center
        )

    // MARK: Subtitle
    enum SubtitleType {
        case common, fetchedKeys(Int), choosingPassPhrase
    }

    func subtitle(for subtitleType: SubtitleType) -> NSAttributedString {
        let subtitle: String

        switch subtitleType {
        case let .fetchedKeys(count):
            subtitle = "Found \(count) key backup\(count > 1 ? "s" : "")"
        case .common:
            subtitle = "setup_description".localized
        case .choosingPassPhrase:
            subtitle = "create_pass_phrase_description".localized
        }

        return subtitle.attributed(.regular(17))
    }

    // MARK: Button
    enum ButtonAction {
        case createKey, importKey, loadAccount, setPassPhrase
    }

    func buttonTitle(for action: ButtonAction) -> NSAttributedString {
        let buttonTitle: String

        switch action {
        case .createKey:
            buttonTitle = "setup_initial_create_key"
        case .importKey:
            buttonTitle = "setup_initial_import_key"
        case .loadAccount:
            buttonTitle = "setup_load"
        case .setPassPhrase:
            buttonTitle = "create_pass_phrase_set_title"
        }

        return buttonTitle
            .localized
            .attributed(
                .regular(17),
                color: .white,
                alignment: .center
            )
    }
}

extension TextFieldCellNode.Input {
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
