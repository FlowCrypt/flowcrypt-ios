//
//  MyMenuViewDecorator.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 19/03/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import UIKit
import FlowCryptUI

protocol MyMenuViewDecoratorType {
    var dividerColor: UIColor { get }
    var backgroundColor: UIColor { get }
    func header(for user: String?, email: String?) -> HeaderNode.Input
}

struct MyMenuViewDecorator: MyMenuViewDecoratorType {
    var dividerColor: UIColor { .dividerColor }
    var backgroundColor: UIColor { .backgroundColor }

    func header(for user: String?, email: String?) -> HeaderNode.Input {
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
            subtitle: email.attributed(.medium(16), color: .white, alignment: .left)
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
    init(_ viewModel: FolderViewModel) {
        self.init(
            attributedText: viewModel.name.attributed(
                .regular(17),
                color: .mainTextColor
            ),
            image: viewModel.image
        )
    }
}

