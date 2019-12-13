//
//  KeyDetailInfoViewController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12/13/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit

final class KeyDetailInfoViewController: ASViewController<TableNode> {
    enum Parts: Int, CaseIterable {
        case keyWord, fingerptint, longId, date, users, separator

        var isSeparator: Bool {
            guard case .separator = self else { return false }
            return true
        }
    }

    private let decorator: KeyDetailInfoDecoratorType
    private let details: [KeyId]
    private let date: Date
    private let user: String

    init(
        details: [KeyId],
        date: Date,
        user: String,
        decorator: KeyDetailInfoDecoratorType = KeyDetailInfoDecorator()
    ) {
        self.details = details
        self.decorator = decorator
        self.date = date
        self.user = user
        super.init(node: TableNode())
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "key_settings_detail_public".localized

        node.delegate = self
        node.dataSource = self
        node.reloadData()
    }
}

extension KeyDetailInfoViewController: ASTableDelegate, ASTableDataSource {
    func numberOfSections(in tableNode: ASTableNode) -> Int {
        details.count
    }

    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        Parts.allCases.count
    }

    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self = self,
                let part = Parts(rawValue: indexPath.row),
                let key = self.details[safe: indexPath.section]
            else {
                return ASCellNode()
            }

            let title = self.decorator.attributedTitle(
                for: part,
                details: key,
                date: self.date,
                user: self.user
            )

            if part.isSeparator {
                return DividerNode(
                    inset: UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
                )
            }
            return KeyTextCellNode(
                title: title,
                insets: self.decorator.insets
            )
        }
    }
}
