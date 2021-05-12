//
//  MyMenuViewDecorator.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 19/03/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import FlowCryptUI
import FlowCryptCommon
import UIKit

protocol MyMenuViewDecoratorType {
    var dividerColor: UIColor { get }
    var backgroundColor: UIColor { get }
    func header(for user: User?, image: UIImage?) -> HeaderNode.Input
    func nodeForAccount(for user: User) -> InfoCellNode.Input
}

struct MyMenuViewDecorator: MyMenuViewDecoratorType {
    var dividerColor: UIColor { .dividerColor }
    var backgroundColor: UIColor { .backgroundColor }

    func header(for user: User?, image: UIImage?) -> HeaderNode.Input {
        HeaderNode.Input(
            title: nameFor(user: user).attributed(.bold(22), color: .white, alignment: .left),
            subtitle: emailFor(user: user).attributed(.medium(18), color: .white, alignment: .left),
            image: image
        )
    }

    func nodeForAccount(for user: User) -> InfoCellNode.Input {
        let name = nameFor(user: user).attributed(.medium(18), color: .black, alignment: .left)
        let email = emailFor(user: user).attributed(.medium(16), color: .black, alignment: .left)
        let text = name.mutable() + "\n".attributed() + email

        return InfoCellNode.Input(attributedText: text, image: nil, insets: .side(16))
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
