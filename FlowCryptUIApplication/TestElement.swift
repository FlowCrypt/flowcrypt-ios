//
//  TestElement.swift
//  FlowCryptUIApplication
//
//  Created by Anton Kharchevskyi on 19/02/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptUI

final public class RecipientsTextField: ASCellNode {
    struct Style {
        var insets = UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4)
        var cornerRadius: CGFloat = 8
        var borderColor: UIColor = .darkGray
        var selectedColor: UIColor = .blue
    }

    struct Recipient {
        let email: NSAttributedString
        var isSelected: Bool
    }

    let collectionNode: ASCollectionNode = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        let collectionNode = ASCollectionNode(collectionViewLayout: layout)
        collectionNode.backgroundColor = .blue
        return collectionNode
    }()


    var recipients: [Recipient] = (1...10).map { _ in
        Recipient(email: testAttributedText(), isSelected: false)
    }

    var textSize: CGSize {
        recipients.first?.email.size() ?? .zero
    }

    public override init() {
        super.init()
        collectionNode.dataSource = self
        collectionNode.delegate = self
        backgroundColor = .red

        automaticallyManagesSubnodes = true
    }

    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        collectionNode.style.preferredSize.height = textSize.height * CGFloat(recipients.count)

        collectionNode.style.preferredSize.width = constrainedSize.max.width

        return ASInsetLayoutSpec(
            insets: .zero,
            child: collectionNode
        )
    }
}

//extension RecipientsTextField: ASCollectionDelegateFlowLayout {
//    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
//        .zero
//    }
//
//    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
//        0
//    }
//
//    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
//        0
//    }
//
//}

extension RecipientsTextField: ASCollectionDelegate, ASCollectionDataSource {
    public func collectionNode(_ collectionNode: ASCollectionNode, numberOfItemsInSection section: Int) -> Int {
        recipients.count
    }

    public func collectionNode(_ collectionNode: ASCollectionNode, nodeBlockForItemAt indexPath: IndexPath) -> ASCellNodeBlock {
        return {
            let node = MenuCellNode(input: MenuCellNode.Input(attributedText: testAttributedText(), image: nil))
            node.backgroundColor = .green
            return node
        }
    }
}
