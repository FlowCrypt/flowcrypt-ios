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

    struct Recipient {
        let email: NSAttributedString
        var isSelected: Bool
    }

    private enum Sections: Int, CaseIterable {
        case emails, textField
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


    var recipients: [Recipient] = (1...10).map { _ in
        Recipient(email: testAttributedText(), isSelected: false)
    }

    public override init() {
        super.init()
        collectionNode.dataSource = self
        collectionNode.delegate = self
        automaticallyManagesSubnodes = true
    }

    var call:(() -> Void)?
    var height: CGFloat {
        let recipientNodeInset: CGFloat = 2
        let recipientsHeight = (textSize.height + recipientNodeInset) * CGFloat(recipients.count)
        let insets = Constants.minimumLineSpacing * CGFloat(recipients.count)
        let height = recipientsHeight + insets + Constants.sectionInset.width
        return height
    }
    var shouldCall = false {
        didSet {
            if shouldCall {
                DispatchQueue.main.async {
                           self.call?()
                       }
            }
        }
    }

    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let minHeight = min(height, UIScreen.main.bounds.height * 0.3)

        if height < UIScreen.main.bounds.height * 0.3 {
            shouldCall = true
            shouldCall = false
        }

        collectionNode.style.preferredSize.height = minHeight
        print("^^ \(minHeight)")
        collectionNode.style.preferredSize.width = constrainedSize.max.width
        collectionNode.backgroundColor = .red
        return ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8),
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
                return RecipientEmailNode(input: RecipientEmailNode.Input(recipient: recipient, width: width))
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
    var textSize: CGSize {
        recipients.first?.email.size() ?? .zero
    }

    var textField: TextFieldNode? {
        (collectionNode.nodeForItem(at: IndexPath(row: 0, section: Sections.textField.rawValue)) as? TextFieldCellNode)?.textField
    }

    func attributedEmail(with string: String) -> NSAttributedString {
        string.attributed(.bold(13), alignment: .center)
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
            setNeedsLayout()
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




