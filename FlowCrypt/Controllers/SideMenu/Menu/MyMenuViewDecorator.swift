//
//  MyMenuViewDecorator.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 19/03/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
import FlowCryptUI
import UIKit

struct MyMenuViewDecorator {
    var dividerColor: UIColor { .dividerColor }
    var backgroundColor: UIColor { .backgroundColor }

    func header(for user: User?, image: UIImage?) -> TextImageNode.Input {
        TextImageNode.Input(
            title: nameFor(user: user).attributed(.bold(22), color: .white, alignment: .left),
            subtitle: emailFor(user: user).attributed(.medium(18), color: .white, alignment: .left),
            image: image,
            backgroundColor: .main
        )
    }

    func nodeForAccount(for user: User, index: Int) -> InfoCellNode.Input {
        let name = nameFor(user: user)
            .attributed(.medium(18), color: .mainTextColor, alignment: .left)
        let email = emailFor(user: user).attributed(.medium(16), color: .mainTextColor, alignment: .left)
        let text = name.mutable()
            + "\n".attributed()
            + email

        return InfoCellNode.Input(
            attributedText: text,
            insets: .side(16),
            accessibilityIdentifier: "aid-account-email-\(index)"
        )
    }

    private func nameFor(user: User?) -> String {
        user?.name.split(separator: " ").first.map(String.init) ?? ""
    }

    private func emailFor(user: User?) -> String {
        user?.email.replacingOccurrences(of: "@gmail.com", with: "") ?? ""
    }
}

extension FolderViewModel {
    static var menuItems: [FolderViewModel] {
        [
            FolderViewModel(
                name: "folder_settings".localized,
                path: "",
                image: UIImage(systemName: "gearshape"),
                itemType: .settings
            ),
            FolderViewModel(
                name: "log_out".localized,
                path: "",
                image: UIImage(systemName: "rectangle.portrait.and.arrow.right"),
                itemType: .logOut
            )
        ]
    }
}

extension InfoCellNode.Input {
    static var addAccount: InfoCellNode.Input {
        .init(
            attributedText: "folder_add_account"
                .localized
                .attributed(.regular(17), color: .mainTextColor),
            image: UIImage(named: "plus")?.tinted(.mainTextColor),
            insets: .side(16),
            backgroundColor: .backgroundColor,
            accessibilityIdentifier: "aid-add-account-btn"
        )
    }

    init(_ viewModel: FolderViewModel) {
        let identifier = viewModel.name.replacingOccurrences(of: " ", with: "-").lowercased()
        self.init(
            attributedText: viewModel.name
                .attributed(.regular(17), color: .mainTextColor),
            image: viewModel.image?.tinted(.mainTextColor),
            accessibilityIdentifier: "aid-menu-bar-item-\(identifier)"
        )
    }
}
