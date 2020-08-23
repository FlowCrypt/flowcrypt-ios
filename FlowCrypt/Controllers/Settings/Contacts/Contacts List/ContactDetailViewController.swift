//
//  ContactDetailViewController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 23/08/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptUI

final class ContactDetailViewController: ASViewController<TableNode> {
    private let decorator: ContactDetailDecoratorType
    private let contact: Contact

    init(
        decorator: ContactDetailDecoratorType = ContactDetailDecorator(),
        contact: Contact
    ) {
        self.decorator = decorator
        self.contact = contact
        super.init(node: TableNode())
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        node.delegate = self
        node.dataSource = self
        title = decorator.title
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard #available(iOS 13.0, *) else { return }
        node.reloadData()
    }
}

extension ContactDetailViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_: ASTableNode, numberOfRowsInSection _: Int) -> Int {
        1
    }

    func tableNode(_: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self = self else { return ASCellNode() }
            return ContactDetailNode(input: self.decorator.nodeInput(with: self.contact))
        }
    }
}
