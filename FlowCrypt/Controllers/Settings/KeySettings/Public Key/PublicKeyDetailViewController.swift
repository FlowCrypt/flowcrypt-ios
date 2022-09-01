//
//  PublicKeyDetailViewController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12/13/19.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptUI

/**
 * View controller which shows information about public key
 * - User can be redirected here from *KeyDetailViewController*
 */
final class PublicKeyDetailViewController: TableNodeViewController {
    private let text: String

    init(text: String) {
        self.text = text
        super.init(node: TableNode())
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
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

extension PublicKeyDetailViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_: ASTableNode, numberOfRowsInSection _: Int) -> Int {
        1
    }

    func tableNode(_: ASTableNode, nodeBlockForRowAt _: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            InfoCellNode(input: .init(
                attributedText: (self?.text ?? "").attributed(.regular(16)),
                image: nil,
                insets: .deviceSpecificTextInsets(top: 16, bottom: 16),
                backgroundColor: .backgroundColor,
                accessibilityIdentifier: "aid-public-key-node"
            ))
        }
    }
}
