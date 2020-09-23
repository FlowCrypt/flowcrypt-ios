//
//  BackupViewDecorator.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 22/09/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import UIKit

protocol BackupViewDecoratorType {
    var sceneTitle: String { get }

    var buttonInsets: UIEdgeInsets { get }
    func buttonTitle(isAnyBackups: Bool) -> NSAttributedString
}

struct BackupViewDecorator: BackupViewDecoratorType {
    let sceneTitle: String = "backup_screen_title"
        .localized

    let buttonInsets: UIEdgeInsets = UIEdgeInsets(top: 8, left: 24, bottom: 8, right: 24)

    func buttonTitle(isAnyBackups: Bool) -> NSAttributedString {
        (isAnyBackups ? "backup_screen_found_action" : "backup_screen_not_found")
            .localized
            .attributed(.bold(14), color: .white, alignment: .center)
    }
}
