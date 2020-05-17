//
//  TestElement.swift
//  FlowCryptUIApplication
//
//  Created by Anton Kharchevskyi on 19/02/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptCommon

public final class RecipientEmailsCellNode: CellNode {
    private enum Constants {
        static let sectionInset = UIEdgeInsets(top: 8, left: 8, bottom: 0, right: 8)
        static let minimumLineSpacing: CGFloat = 4
    }

    public struct Input {
        public let email: NSAttributedString
        public var isSelected: Bool

        public init(
            email: NSAttributedString,
            isSelected: Bool
        ) {
            self.email = email
            self.isSelected = isSelected
        }
    }

    private var onSelect: ((IndexPath) -> Void)?

    public lazy var collectionNode: ASCollectionNode = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 1
        layout.minimumLineSpacing = Constants.minimumLineSpacing
        layout.sectionInset = Constants.sectionInset
        let collectionNode = ASCollectionNode(collectionViewLayout: layout)
        collectionNode.backgroundColor = .clear
        return collectionNode
    }()

    public var recipients: [Input] = []

    public init(recipients: [Input]) {
        self.recipients = recipients
        super.init()
        collectionNode.dataSource = self
        collectionNode.delegate = self
        automaticallyManagesSubnodes = true
    }

    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        guard recipients.isNotEmpty else {
            return ASInsetLayoutSpec(insets: .zero, child: collectionNode)
        }
        let recipientNodeInset: CGFloat = 1
        let textSize: CGSize = recipients.first?.email.size() ?? .zero
        let recipientsHeight = (textSize.height + recipientNodeInset) * CGFloat(recipients.count)
        let insets = Constants.minimumLineSpacing * CGFloat(recipients.count - 1)
        let height = recipientsHeight + insets + Constants.sectionInset.width

        collectionNode.style.preferredSize.height = height
        collectionNode.style.preferredSize.width = constrainedSize.max.width

        return ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8),
            child: collectionNode
        )
    }
}

extension RecipientEmailsCellNode {
    public func onItemSelect(_ action: ((IndexPath) -> Void)?) -> Self {
        onSelect = action
        return self
    }
}

extension RecipientEmailsCellNode: ASCollectionDelegate, ASCollectionDataSource {
    public func collectionNode(_: ASCollectionNode, numberOfItemsInSection _: Int) -> Int {
        recipients.count
    }

    public func collectionNode(_ collectionNode: ASCollectionNode, nodeBlockForItemAt indexPath: IndexPath) -> ASCellNodeBlock {
        let width = collectionNode.style.preferredSize.width
        return { [weak self] in
            guard let recipient = self?.recipients[indexPath.row] else { assertionFailure(); return ASCellNode() }
            return RecipientEmailNode(input: RecipientEmailNode.Input(recipient: recipient, width: width))
        }
    }

    public func collectionNode(_: ASCollectionNode, didSelectItemAt indexPath: IndexPath) {
        onSelect?(indexPath)
    }
}
