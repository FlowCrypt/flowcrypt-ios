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
    struct Input {
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
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 1
        layout.minimumLineSpacing = 1
        layout.sectionInset = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)

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
        collectionNode.style.preferredSize.height = textSize.height * CGFloat(recipients.count) * 2

        collectionNode.style.preferredSize.width = constrainedSize.max.width

        return ASInsetLayoutSpec(
            insets: .zero,
            child: collectionNode
        )
    }
}

extension RecipientsTextField: ASCollectionDelegate, ASCollectionDataSource {
    public func numberOfSections(in collectionNode: ASCollectionNode) -> Int {
        2//Sections.allCases.count
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
//                return EmailNode(input: Recipient(email: NSAttributedString(string: "NSAttributedString \(indexPath.row)"), isSelected: false))
                return EmailNode(input: EmailNode.Input(recipient: recipient, width: width))
            case .textField:
                let node = TextFieldCellNode(input: TextFieldCellNode.Input(width: width)) { action in
                    print("^^ \(action)")
                }.onReturn { [weak self] textField -> Bool in
                    self?.handleEndEditingAction(with: textField)
                    return true
                }
                return node
            }
        }
    }
}

extension RecipientsTextField {
    func attributedEmail(with string: String) -> NSAttributedString {
        string.attributed(.bold(13))
    }
}

extension RecipientsTextField {
    private func handleEndEditingAction(with textField: UITextField) {
        textField.resignFirstResponder()

        guard let text = textField.text else {
            print("^^ Empty")
            return
        }

        print("^^  onReturn \(text)")
        recipients.append(RecipientsTextField.Recipient(email: attributedEmail(with: text), isSelected: false))
        collectionNode.reloadData()
    }


}


final class EmailNode: CellNode {
    struct Input {
        let recipient: RecipientsTextField.Recipient
        let width: CGFloat
    }

    let titleNode = ASTextNode()
    let input: Input

    init(input: Input) {
        self.input = input
        super.init()
        self.titleNode.attributedText = input.recipient.email
        self.backgroundColor = input.recipient.isSelected ? .red : .orange
    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        titleNode.style.preferredSize.width = input.width
        titleNode.style.preferredSize.height = input.recipient.email.size().height
        return ASInsetLayoutSpec(insets: .zero, child: titleNode)
    }
}

