//
//  TestElement.swift
//  FlowCryptUIApplication
//
//  Created by Anton Kharchevskyi on 19/02/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptCommon

final public class RecipientEmailsCellNode: CellNode {
    public typealias RecipientTap = (RecipientEmailTapAction) -> Void

    public enum RecipientEmailTapAction {
        case select(IndexPath)
        case imageTap(IndexPath)
    }

    private enum Constants {
        static let sectionInset = UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0)
        static let minimumLineSpacing: CGFloat = 4
    }

    private var onAction: RecipientTap?

    private lazy var layout: LeftAlignedCollectionViewFlowLayout = {
        let layout = LeftAlignedCollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 1
        layout.minimumLineSpacing = Constants.minimumLineSpacing
        layout.sectionInset = Constants.sectionInset
        return layout
    }()

    public lazy var collectionNode: ASCollectionNode = {
        let node = ASCollectionNode(collectionViewLayout: layout)
        node.accessibilityIdentifier = "aid-recipients-list"
        node.backgroundColor = .clear
        return node
    }()

    private var collectionLayoutHeight: CGFloat
    private var recipients: [Input] = []

    public init(recipients: [Input], height: CGFloat) {
        self.recipients = recipients
        self.collectionLayoutHeight = height
        super.init()
        collectionNode.dataSource = self
        collectionNode.delegate = self

        DispatchQueue.main.async {
            self.collectionNode.view.contentInsetAdjustmentBehavior = .never
        }

        automaticallyManagesSubnodes = true
    }

    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        guard recipients.isNotEmpty else {
            return ASInsetLayoutSpec(insets: .zero, child: collectionNode)
        }

        collectionNode.style.preferredSize.height = collectionLayoutHeight
        collectionNode.style.preferredSize.width = constrainedSize.max.width

        return ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8),
            child: collectionNode
        )
    }
}

extension RecipientEmailsCellNode {
    public func onItemSelect(_ action: RecipientTap?) -> Self {
        self.onAction = action
        return self
    }

    public func onLayoutHeightChanged(_ completion: @escaping (CGFloat) -> Void) -> Self {
        self.layout.onHeightChanged = completion
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

            return RecipientEmailNode(
                input: RecipientEmailNode.Input(recipient: recipient, width: width),
                index: indexPath.row
            )
                .onTapAction { [weak self] action in
                    switch action {
                    case .image: self?.onAction?(.imageTap(indexPath))
                    case .text: self?.onAction?(.select(indexPath))
                    }
                }
        }
    }
}
