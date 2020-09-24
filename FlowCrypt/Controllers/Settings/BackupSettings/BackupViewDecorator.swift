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
    func buttonTitle(for state: BackupViewController.State) -> NSAttributedString
    func description(for state: BackupViewController.State) -> NSAttributedString
}

struct BackupViewDecorator: BackupViewDecoratorType {
    let sceneTitle: String = "backup_screen_title"
        .localized

    let buttonInsets: UIEdgeInsets = UIEdgeInsets(top: 8, left: 24, bottom: 8, right: 24)

    func buttonTitle(for state: BackupViewController.State) -> NSAttributedString {
        (state.isAnyBackups ? "backup_screen_found_action" : "backup_screen_not_found")
            .localized
            .uppercased()
            .attributed(.bold(14), color: .white, alignment: .center)
    }

    func description(for state: BackupViewController.State) -> NSAttributedString {
        let title: String
        switch state {
        case .idle:
            title = "Fetching backups..."
        case let .backups(keys):
            title = "backup_screen_found".localized
                + " \(keys.count)"
                + "\n\n"
                + "backup_screen_found_description".localized
        case .noBackups:
            title = "backup_screen_not_found".localized
                + "\n\n"
                + "backup_screen_not_found_description".localized
        }

        return title
            .localized
            .attributed(.medium(14), color: .textColor, alignment: .center)
    }
}
