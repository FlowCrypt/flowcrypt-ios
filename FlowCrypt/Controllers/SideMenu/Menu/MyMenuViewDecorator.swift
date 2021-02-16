//
//  MyMenuViewDecorator.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 19/03/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import FlowCryptUI
import UIKit

protocol MyMenuViewDecoratorType {
    var dividerColor: UIColor { get }
    var backgroundColor: UIColor { get }
    func header(for user: String?, email: String?, image: UIImage?) -> HeaderNode.Input
}

struct MyMenuViewDecorator: MyMenuViewDecoratorType {
    var dividerColor: UIColor { .dividerColor }
    var backgroundColor: UIColor { .backgroundColor }

    func header(for user: String?, email: String?, image: UIImage?) -> HeaderNode.Input {
        let name = user?
            .split(separator: " ")
            .first
            .map(String.init)
            ?? ""

        let email = email?
            .replacingOccurrences(of: "@gmail.com", with: "")
            ?? ""

        return HeaderNode.Input(
            title: name.attributed(.bold(20), color: .white, alignment: .left),
            subtitle: email.attributed(.medium(16), color: .white, alignment: .left),
            image: image
        )
    }
}

extension FolderViewModel {
    static var menuItems: [FolderViewModel] {
        [
            FolderViewModel(
                name: "Settings",
                path: "",
                image: UIImage(named: "settings")?.tinted(.mainTextColor),
                itemType: .settings
            ),
            FolderViewModel(
                name: "Log out",
                path: "",
                image: UIImage(named: "exit")?.tinted(.mainTextColor),
                itemType: .logOut
            )
        ]
    }
}

extension InfoCellNode.Input {
    static let addAccount: InfoCellNode.Input = .init(
        attributedText: "folder_add_account".localized
            .attributed(.regular(17), color: .mainTextColor),
        image: #imageLiteral(resourceName: "plus").tinted(.mainTextColor),
        insets: .side(16),
        backgroundColor: .backgroundColor
    )

    init(_ viewModel: FolderViewModel) {
        self.init(
            attributedText: viewModel.name
                .attributed(.regular(17), color: .mainTextColor),
            image: viewModel.image
        )
    }
}
