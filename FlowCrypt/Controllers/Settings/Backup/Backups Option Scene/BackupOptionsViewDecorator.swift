//
//  BackupOptionsViewDecorator.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 27/09/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptUI
import UIKit

protocol BackupOptionsViewDecoratorType {
    var sceneTitle: String { get }
    var insets: UIEdgeInsets { get }

    func buttonText(for backupOption: BackupOption) -> NSAttributedString
    func description(for backupOption: BackupOption) -> NSAttributedString
    func checkboxContext(for part: BackupOptionsViewController.Parts, isSelected: Bool) -> CheckBoxTextNode.Input
}

struct BackupOptionsViewDecorator: BackupOptionsViewDecoratorType {
    let sceneTitle = "backup_option_screen_title".localized
    let insets: UIEdgeInsets = .side(16)

    func buttonText(for backupOption: BackupOption) -> NSAttributedString {
        (backupOption.isEmail
            ? "backup_option_screen_email_action"
            : "backup_option_screen_file_action"
        )
        .localized
        .uppercased()
        .attributed(.bold(14), color: .white, alignment: .center)
    }

    func description(for backupOption: BackupOption) -> NSAttributedString {
        (backupOption.isEmail
            ? "backup_option_screen_email_description"
            : "backup_option_screen_download_description"
        )
        .localized
        .attributed(.medium(14), color: .textColor, alignment: .center)
    }

    func checkboxContext(
        for part: BackupOptionsViewController.Parts,
        isSelected: Bool
    ) -> CheckBoxTextNode.Input {

        let title: String

        switch part {
        case .email: title = "backup_option_screen_email"
        case .download: title = "backup_option_screen_download"
        default: title = ""
        }

        return CheckBoxTextNode.Input.common(
            with: title.localized,
            isSelected: isSelected
        )
    }
}
