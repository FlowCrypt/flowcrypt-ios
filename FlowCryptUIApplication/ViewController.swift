//
//  ViewController.swift
//  FlowCryptUIApplication
//
//  Created by Anton Kharchevskyi on 19/02/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptCommon
import FlowCryptUI

final class ViewController: TableNodeViewController {
    enum Elements: Int, CaseIterable {
        case header
        case divider
        case menu
        case emailRecipients
        case emailTextField
    }

    private lazy var composeButton = ComposeButtonNode { [weak self] in
    }

    init() {
        super.init(node: TableNode())
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        node.delegate = self
        node.dataSource = self
        node.reloadData()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let offset: CGFloat = 16
        let size = CGSize(width: 50, height: 50)

        composeButton.frame = CGRect(
            x: node.bounds.maxX - offset - size.width,
            y: node.bounds.maxY - offset - size.height - 40,
            width: size.width,
            height: size.height
        )
        composeButton.cornerRadius = size.width / 2
    }

    // MARK: - Recipient Text Field

    enum Constants {
        static let endTypingCharacters = [",", " "]
    }

    var recipients: [RecipientEmailsCellNode.Input] = (1 ... 10).map { _ in
        RecipientEmailsCellNode.Input(email: testAttributedText())
    }
}

extension ViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_: ASTableNode, numberOfRowsInSection _: Int) -> Int {
        Elements.allCases.count
    }

    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        let width = tableNode.style.preferredSize.width
        return {
            let element = Elements(rawValue: indexPath.row)!
            switch element {
            case .header:
                return TextImageNode(input: nil)
            case .divider:
                return DividerCellNode(color: .black, height: 10)
            case .menu:
                let title = NSAttributedString(string: "Example of recipients text field", attributes: [NSAttributedString.Key.foregroundColor: UIColor.red])

                let input = InfoCellNode.Input(
                    attributedText: title,
                    image: nil
                )
                return InfoCellNode(input: input)
            case .emailRecipients:
                return RecipientEmailsCellNode(recipients: self.recipients)
                    .onItemSelect { [weak self] indexPath in
                        self?.handleRecipientSelection(with: indexPath)
                    }
            case .emailTextField:
                let node = TextFieldCellNode(input: TextFieldCellNode.Input(width: width)) { [weak self] action in
                    self?.handleTextFieldAction(with: action)
                }
                .onShouldReturn { [weak self] textField -> Bool in
                    self?.shouldReturn(with: textField) ?? true
                }
                .onShouldChangeCharacters { [weak self] textField, character -> (Bool) in
                    self?.shouldChange(with: textField, and: character) ?? true
                }
                return node
            }
        }
    }

    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        let element = Elements(rawValue: indexPath.row)!

        switch element {
        case .divider:
            tableNode.reloadData()
        case .menu:
            break
        default:
            break
        }
    }
}

// MARK: - Recipient Text Field

extension ViewController {
    private var textField: TextFieldNode? {
        (node.nodeForRow(at: IndexPath(row: Elements.emailTextField.rawValue, section: 0)) as? TextFieldCellNode)?.textField
    }

    private var recipientsIndexPath: IndexPath {
        IndexPath(row: Elements.emailRecipients.rawValue, section: 0)
    }

    private func attributedEmail(with string: String) -> NSAttributedString {
        NSAttributedString(
            string: string,
            attributes: [
                NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14),
                NSAttributedString.Key.foregroundColor: UIColor.black,
            ]
        )
    }

    private func shouldReturn(with textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    private func shouldChange(with textField: UITextField, and character: String) -> Bool {
        guard let text = textField.text else { return true }

        if text.isEmpty {
            // Pasted string
            let recipients = Constants.endTypingCharacters.map(Character.init)
                .flatMap { character.split(separator: $0) }
                .dropFirst()
                .map { String($0) }
                .filter { !Constants.endTypingCharacters.contains($0) }

            guard recipients.isNotEmpty else { return true }
            for recipient in recipients {
                handleEndEditingAction(with: recipient)
            }
            return false
        } else if Constants.endTypingCharacters.contains(character) {
            handleEndEditingAction(with: textField.text)
            return false
        } else {
            return true
        }
    }

    private func handleTextFieldAction(with action: TextFieldActionType) {
        switch action {
        case let .deleteBackward(textField):
            handleBackspaceAction(with: textField)
        case let .didEndEditing(text):
            handleEndEditingAction(with: text)
        default:
            break
        }
    }

    private func handleEndEditingAction(with text: String?) {
        guard let text, !text.isEmpty else { return }
        recipients = recipients.map { recipient in
            var recipient = recipient
            recipient.state = .selectedState
            return recipient
        }
        recipients.append(RecipientEmailsCellNode.Input(email: attributedEmail(with: text)))
        node.reloadRows(at: [recipientsIndexPath], with: .fade)

        let endIndex = recipients.endIndex - 1
        let collectionNode = (node.nodeForRow(at: recipientsIndexPath) as? RecipientEmailsCellNode)?.collectionNode
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            collectionNode?.scrollToItem(at: IndexPath(row: endIndex, section: 0), at: .bottom, animated: true)
        }
        textField?.reset()
    }

    private func handleBackspaceAction(with textField: UITextField) {
        guard textField.text == "" else { return }

        let selectedRecipients = recipients
            .filter(\.state.isSelected)

        guard selectedRecipients.isEmpty else {
            // remove selected recipients
            recipients = recipients.filter { !$0.state.isSelected }
            node.reloadRows(at: [recipientsIndexPath], with: .fade)
            return
        }

        if let lastRecipient = recipients.popLast() {
            // select last recipient in a list
            var last = lastRecipient
            last.state = .selectedState
            recipients.append(last)
            node.reloadRows(at: [recipientsIndexPath], with: .fade)
        } else {
            // dismiss keyboard if no recipients left
            textField.resignFirstResponder()
        }
    }

    private func handleRecipientSelection(with indexPath: IndexPath) {
        var recipient = recipients[indexPath.row]

        if recipient.state.isSelected {
            recipient.state = .idleState
        } else {
            recipient.state = .errorState
        }

        node.reloadRows(at: [recipientsIndexPath], with: .fade)
        if !(textField?.isFirstResponder() ?? true) {
            textField?.becomeFirstResponder()
        }
        textField?.reset()
    }
}
