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
                return EmailNode(input: EmailNode.Input(recipient: recipient, width: width))
            case .textField:
                let node = TextFieldCellNode(input: TextFieldCellNode.Input(width: width)) { [weak self] action in
                    self?.handleTextFieldAction(with: action)
                }
                .onShouldReturn { [weak self] textField -> Bool in
                    self?.shouldReturn(with: textField) ?? true
                }
                .onShouldChangeCharacters { [weak self] (textField, character) -> (Bool) in
                    self?.shouldChange(with: textField, and: character) ?? true
                }
                return node
            }
        }
    }
}

extension RecipientsTextField {
    var textField: TextFieldNode? {
        (collectionNode.nodeForItem(at: IndexPath(row: 0, section: Sections.textField.rawValue)) as? TextFieldCellNode)?.textField
    }

    func attributedEmail(with string: String) -> NSAttributedString {
        string.attributed(.bold(13))
    }
}

extension RecipientsTextField {
    private func shouldReturn(with textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    private func shouldChange(with textField: UITextField, and character: String) -> Bool {
        guard let text = textField.text else { return true }

        if text.isEmpty {
            return true
        } else if character == "," {
            handleEndEditingAction(with: textField.text)
            return false
        } else {
            return true
        }

    }

    private func handleTextFieldAction(with action: TextFieldActionType) {
        print("^^ \(action)")
        switch action {
        case let .deleteBackward(textField):
            handleBackspaceAction(with: textField)
        case let .didEndEditing(text):
            handleEndEditingAction(with: text)
        case let .editingChanged(text):
            guard text == "," else { return }
            
        default:
            break
        }
    }

    private func handleEndEditingAction(with text: String?) {
        guard let text = text, !text.isEmpty else { return }
        recipients.append(RecipientsTextField.Recipient(email: attributedEmail(with: text), isSelected: false))
        collectionNode.insertItems(at: [IndexPath(row: recipients.count - 1, section: 0)])
        textField?.reset()
    }

    private func handleBackspaceAction(with textField: UITextField) {
        guard textField.text == "" else { return }

        if let index = recipients.firstIndex(where: { $0.isSelected }) {
            recipients.remove(at: index)
            collectionNode.deleteItems(at: [IndexPath(row: index, section: 0)])
        } else if let lastRecipient = recipients.popLast() {
            var last = lastRecipient
            last.isSelected = true
            recipients.append(last)
            collectionNode.reloadItems(at: [IndexPath(row: recipients.count - 1, section: 0)])
        } else {
            textField.resignFirstResponder()
        }
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

