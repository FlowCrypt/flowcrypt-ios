//
//  BackupViewDecorator.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 22/09/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit

struct BackupViewDecorator {
    let sceneTitle = "backup_screen_title".localized

    func buttonTitle(for state: BackupViewController.State) -> NSAttributedString {
        (state.hasAnyBackups ? "backup_screen_found_action" : "backup_screen_not_found_action")
            .localized
            .uppercased()
            .attributed(.bold(14), color: .white, alignment: .center)
    }

    func description(for state: BackupViewController.State) -> NSAttributedString {
        let title: String
        let subtitle: String

        switch state {
        case .idle:
            title = "backup_screen_fetching_backups".localized
            subtitle = ""
        case let .backups(keys):
            title = "backup_screen_found".localized
                + " \(keys.count)"
            subtitle = "\n\n" + "backup_screen_found_description".localized
        case .noBackups:
            title = "backup_screen_not_found".localized
            subtitle = "\n\n" + "backup_screen_not_found_description".localized
        }

        let titleAttributedString = title.attributed(.bold(18), color: .mainTextColor, alignment: .center)
        let subtitleAttrinutedString = subtitle.attributed(.medium(14), color: .mainTextColor, alignment: .center)
        let result = NSMutableAttributedString(attributedString: titleAttributedString)
        result.append(subtitleAttrinutedString)

        return result
    }
}
