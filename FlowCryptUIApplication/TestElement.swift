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

    private enum Sections: Int, CaseIterable {
        case emails, textField
    }

    let layout = UICollectionViewFlowLayout()

    lazy var collectionNode: ASCollectionNode = {
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 1
        layout.minimumLineSpacing = 1
        layout.sectionInset = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)

        let collectionNode = ASCollectionNode(collectionViewLayout: layout)
//        let collectionNode = ASCollectionNode(layoutDelegate: ASCollectionFlowLayoutDelegate(), layoutFacilitator: nil)
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
        collectionNode.style.preferredSize.height = textSize.height * CGFloat(recipients.count)// * 2

        collectionNode.style.preferredSize.width = constrainedSize.max.width

        return ASInsetLayoutSpec(
            insets: .zero,
            child: collectionNode
        )
    }
}

extension RecipientsTextField: ASCollectionDelegate, ASCollectionDataSource {
    public func numberOfSections(in collectionNode: ASCollectionNode) -> Int {
        1//Sections.allCases.count
    }

    public func collectionNode(_ collectionNode: ASCollectionNode, numberOfItemsInSection section: Int) -> Int {
        guard let section = Sections(rawValue: section) else { assertionFailure(); return 0 }
        switch section {
        case .emails: return recipients.count
        case .textField: return 1
        }
    }

    public func collectionNode(_ collectionNode: ASCollectionNode, nodeBlockForItemAt indexPath: IndexPath) -> ASCellNodeBlock {
        let width = collectionNode.style.preferredSize.width
        return { [weak self] in
            guard let section = Sections(rawValue: indexPath.section) else { assertionFailure(); return ASCellNode() }

            switch section {
            case .emails:
                guard let recipient = self?.recipients[indexPath.row] else { assertionFailure(); return ASCellNode() }
                return EmailNode(input: recipient)
            case .textField:
                let node = TextFieldCellNode(input: TextFieldCellNode.Input(width: width)) { action in
                    print(action)
                }
                return node
            }
        }
    }
}


final class EmailNode: CellNode {
    let titleNode = ASTextNode()

    init(input: RecipientsTextField.Recipient) {
        super.init()
        titleNode.attributedText = input.email
        backgroundColor = .orange
    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        return ASInsetLayoutSpec(insets: .zero, child: titleNode)
    }
}
