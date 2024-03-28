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
        let text = switch titleType {
        case .setup, .createKey, .choosePassPhrase:
            "setup_title"
        case .enterPassPhrase, .importKey:
            "import_key_description"
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
        let subtitle = switch subtitleType {
        case let .fetchedKeys(count):
            "Found %@ key backup(s)".localizePluralsWithArguments(count)
        case let .fetchedEKMKeys(count):
            "Fetched %@ key(s) on EKM".localizePluralsWithArguments(count)
        case .common:
            "setup_description".localized
        case .choosingPassPhrase:
            "create_pass_phrase_tips".localized
        case .noBackups:
            "setup_no_backups".localized // todo - edit
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
        let buttonTitle = switch action {
        case .createKey:
            "setup_initial_create_key"
        case .importKey:
            "setup_initial_import_key"
        case .loadAccount:
            "setup_load"
        case .setPassPhrase:
            "create_pass_phrase_set_title"
        case .pasteBoard:
            "import_key_paste"
        case .passPhraseContinue:
            "import_key_continue"
        case .passPhraseChooseAnother:
            "import_key_choose"
        case .fileImport:
            "import_key_file"
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
