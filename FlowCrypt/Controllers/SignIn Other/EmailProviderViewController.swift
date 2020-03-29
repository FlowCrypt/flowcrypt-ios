//
//  EmailProviderViewController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 29/03/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptUI

final class EmailProviderViewController: ASViewController<TableNode> {
    enum Section {
        case account(AccountPart)
        case imap(ServerPart)
        case smtp(ServerPart)
        case other(OtherSMTP)

        static let numberOfSections: Int = 4

        static func numberOfItems(for section: Int) -> Int {
            switch section {
            case 0: return AccountPart.allCases.count
            case 1, 2: return ServerPart.allCases.count
            case 3: return OtherSMTP.allCases.count
            default: return 0
            }
        }

        init?(indexPath: IndexPath) {
            switch indexPath.section {
            case 0:
                guard let part = AccountPart(rawValue: indexPath.row) else { return nil }
                self = .account(part)
            case 1:
                guard let part = ServerPart(rawValue: indexPath.row) else { return nil }
                self = .imap(part)
            case 2:
                guard let part = ServerPart(rawValue: indexPath.row) else { return nil }
                self = .smtp(part)
            case 3:
                guard let part = OtherSMTP(rawValue: indexPath.row) else { return nil }
                self = .other(part)
            default:
                return nil
            }
        }
    }

    enum AccountPart: Int, CaseIterable {
        case title, email, username, password
    }

    enum ServerPart: Int, CaseIterable {
        case title, server, port, security
    }

    enum OtherSMTP: Int, CaseIterable {
        case title, name, password
    }

    private let decorator: EmailProviderViewDecoratorType

    init(
        decorator: EmailProviderViewDecoratorType = EmailProviderViewDecorator()
    ) {
        self.decorator = decorator

        super.init(node: TableNode())
        node.delegate = self
        node.dataSource = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension EmailProviderViewController: ASTableDelegate, ASTableDataSource {
    func numberOfSections(in tableNode: ASTableNode) -> Int {
        Section.numberOfSections
    }

    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        Section.numberOfItems(for: section)
    }

    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        { [weak self] in
            guard let self = self, let section = Section(indexPath: indexPath) else { return ASCellNode() }

            switch section {
            case .account(.title): return self.titleNode(for: indexPath)
            case .imap(.title): return self.titleNode(for: indexPath)
            case .smtp(.title): return self.titleNode(for: indexPath)
            case .other(.title): return self.titleNode(for: indexPath)
            default: return ASCellNode()
            }
        }
    }
}

extension EmailProviderViewController {
    private func titleNode(for indexPath: IndexPath) -> ASCellNode {
        guard let section = Section(indexPath: indexPath) else { assertionFailure(); return ASCellNode() }
        let input = InfoCellNode.Input(
            attributedText: decorator.title(for: section),
            image: nil
        )
        
        return InfoCellNode(input: input)
    }
}
