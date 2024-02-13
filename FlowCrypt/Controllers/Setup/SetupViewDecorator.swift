//
//  SetupViewDecorator.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 29.10.2019.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
import FlowCryptUI
import UIKit

struct SetupViewInsets {
    let titleInset = UIEdgeInsets.deviceSpecificTextInsets(top: 64, bottom: 64)
    let subTitleInset = UIEdgeInsets.deviceSpecificInsets(top: 8, bottom: 24)
    let dividerInsets = UIEdgeInsets.deviceSpecificInsets(top: 0, bottom: 0)
}

struct SetupViewDecorator {
    let insets = SetupViewInsets()

    let passPhraseLostDescription = "create_pass_phrase_lost"
        .localized
        .attributed(
            .regular(16),
            color: .lightGray,
            alignment: .center
        )

    // MARK: Title
    enum TitleType {
        case setup, enterPassPhrase, choosePassPhrase, importKey, createKey
    }

    func title(for titleType: TitleType) -> NSAttributedString {
        let text: String

        switch titleType {
        case .setup, .createKey, .choosePassPhrase:
            text = "setup_title"
        case .enterPassPhrase, .importKey:
            text = "import_key_description"
        }

        return text
            .localized
            .attributed(
                .bold(35),
                color: .mainTextColor,
                alignment: .center
            )
    }

    func sceneTitle(for titleType: TitleType) -> String {
        switch titleType {
        case .setup:
            return "FlowCrypt"
        case .enterPassPhrase, .importKey:
            return "import_key_title".localized
        case .createKey:
            return "setup_create_key_title".localized
        case .choosePassPhrase:
            return "setup_choose_pass_title".localized
        }
    }

    // MARK: Subtitle
    enum SubtitleType {
        case common, fetchedKeys(Int), fetchedEKMKeys(Int), choosingPassPhrase, noBackups
    }

    func subtitle(for subtitleType: SubtitleType) -> NSAttributedString {
        let subtitle: String

        switch subtitleType {
        case let .fetchedKeys(count):
            subtitle = "Found %@ key backup(s)".localizePluralsWithArguments(count)
        case let .fetchedEKMKeys(count):
            subtitle = "Fetched %@ key(s) on EKM".localizePluralsWithArguments(count)
        case .common:
            subtitle = "setup_description".localized
        case .choosingPassPhrase:
            subtitle = "create_pass_phrase_tips".localized
        case .noBackups:
            subtitle = "setup_no_backups".localized // todo - edit
        }

        return subtitle
            .attributed(
                .regular(17),
                alignment: .center
            )
    }

    var subtitleStyle: (String) -> NSAttributedString {
        { $0.attributed(.regular(17), alignment: .center) }
    }

    // MARK: Button
    enum ButtonAction {
        case createKey, importKey, loadAccount, setPassPhrase, pasteBoard, passPhraseContinue, passPhraseChooseAnother, fileImport
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
        case .pasteBoard:
            buttonTitle = "import_key_paste"
        case .passPhraseContinue:
            buttonTitle = "import_key_continue"
        case .passPhraseChooseAnother:
            buttonTitle = "import_key_choose"
        case .fileImport:
            buttonTitle = "import_key_file"
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
    static let passPhraseTextFieldStyle = TextFieldCellNode.Input(
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
        insets: .deviceSpecificInsets(top: 0, bottom: 0),
        accessibilityIdentifier: "aid-enter-passphrase-input"
    )
}
