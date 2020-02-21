//
//  TestElement.swift
//  FlowCryptUIApplication
//
//  Created by Anton Kharchevskyi on 19/02/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptUI
import FlowCryptCommon

final public class RecipientsTextField: CellNode {
    enum Constants {
        static let sectionInset = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        static let minimumLineSpacing: CGFloat = 4
    }

    public struct Recipient {
        let email: NSAttributedString
        var isSelected: Bool

        public init(
            email: NSAttributedString,
            isSelected: Bool
        ) {
            self.email = email
            self.isSelected = isSelected
        }
    }

    lazy var collectionNode: ASCollectionNode = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 1
        layout.minimumLineSpacing = Constants.minimumLineSpacing
        layout.sectionInset = Constants.sectionInset
        let collectionNode = ASCollectionNode(collectionViewLayout: layout)
        return collectionNode
    }()

    public var recipients: [Recipient] = []

    public init(recipients: [Recipient]) {
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
        let recipientNodeInset: CGFloat = 2
        let textSize: CGSize = recipients.first?.email.size() ?? .zero
        let recipientsHeight = (textSize.height + recipientNodeInset) * CGFloat(recipients.count)
        let insets = Constants.minimumLineSpacing * CGFloat(recipients.count)
        let height = recipientsHeight + insets + Constants.sectionInset.width
        let minHeight = min(height, UIScreen.main.bounds.height * 0.3)

        collectionNode.style.preferredSize.height = minHeight
        collectionNode.style.preferredSize.width = constrainedSize.max.width

        return ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8),
            child: collectionNode
        )
    }

    private var onSelect: ((IndexPath) -> Void)?

    public func onItemSelect(_ action: ((IndexPath) -> Void)?) -> Self {
        self.onSelect = action
        return self
    }
}

extension RecipientsTextField: ASCollectionDelegate, ASCollectionDataSource {
    public func collectionNode(_ collectionNode: ASCollectionNode, numberOfItemsInSection section: Int) -> Int {
        recipients.count
    }

    public func collectionNode(_ collectionNode: ASCollectionNode, nodeBlockForItemAt indexPath: IndexPath) -> ASCellNodeBlock {
        let width = collectionNode.style.preferredSize.width
        return { [weak self] in
            guard let recipient = self?.recipients[indexPath.row] else { assertionFailure(); return ASCellNode() }
            return RecipientEmailNode(input: RecipientEmailNode.Input(recipient: recipient, width: width))
        }
    }

    public func collectionNode(_ collectionNode: ASCollectionNode, didSelectItemAt indexPath: IndexPath) {
        onSelect?(indexPath)
    }
}



