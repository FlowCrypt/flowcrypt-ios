//
//  BackupSelectKeyDecorator.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 17.10.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
import FlowCryptUI
import UIKit

protocol BackupSelectKeyDecoratorType {
    var sceneTitle: String { get }

    func checkboxContext(for key: KeyDetails, isSelected: Bool) -> CheckBoxTextNode.Input
}

struct BackupSelectKeyDecorator: BackupSelectKeyDecoratorType {
    let sceneTitle = "backup_select_key_screen_title".localized

    func checkboxContext(
        for key: KeyDetails,
        isSelected: Bool
    ) -> CheckBoxTextNode.Input {

        let title = key.users
            .joined(separator: " ")
            .attributed(.medium(16))

        let subtitle = key.ids
            .compactMap { $0.fingerprint.separate(every: 4, with: " ") }
            .joined(separator: "\n")
            .attributed(.regular(12), color: .main)

        let checkboxColor: UIColor = isSelected
            ? .main
            : .lightGray

        return CheckBoxTextNode.Input(
            title: title,
            subtitle: subtitle,
            insets: UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16),
            preferredSize: CGSize(width: 30, height: 30),
            checkBoxInput: CheckBoxNode.Input(
                color: checkboxColor,
                strokeWidth: 2
            )
        )
    }
}
