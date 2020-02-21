//
//  ViewController.swift
//  FlowCryptUIApplication
//
//  Created by Anton Kharchevskyi on 19/02/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import UIKit
import AsyncDisplayKit
import FlowCryptUI
import FlowCryptCommon

final class ViewController: ASViewController<ASTableNode> {
    enum Elements: Int, CaseIterable {
        case divider
        case menu
        case emailRecipients
        case emailTextField
    }

    init() {
        super.init(node: ASTableNode())
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.node.delegate = self
        self.node.dataSource = self
        self.node.reloadData()
    }

    // MARK: - Recipient Text Field

    var recipients: [RecipientsTextField.Recipient] = (1...10).map { _ in
        RecipientsTextField.Recipient(email: testAttributedText(), isSelected: false)
    }
}

extension ViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        Elements.allCases.count
    }

    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        let width = tableNode.style.preferredSize.width
        return {
            let element = Elements(rawValue: indexPath.row)!
            switch element {
            case .divider:
                return DividerCellNode(color: .red, height: 50)
            case .menu:
                let title = NSAttributedString(string: "tiasmfasfmasmftlmmme", attributes: [NSAttributedString.Key.foregroundColor : UIColor.red])

                let input = MenuCellNode.Input(
                    attributedText: title,
                    image: nil
                )
                let n = MenuCellNode(input: input)
                print(n)
                return n
            case .emailRecipients:
                return RecipientsTextField(recipients: self.recipients)
                    .onItemSelect { [weak self] indexPath in
                        guard let self = self else { return }
                        self.recipients[indexPath.row].isSelected.toggle()
                        self.node.reloadRows(at: [self.recipientsIndexPath], with: .fade)
                        self.textField?.reset()
                    }
            case .emailTextField:
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
    var textField: TextFieldNode? {
        (node.nodeForRow(at: IndexPath(row: Elements.emailTextField.rawValue, section: 0)) as? TextFieldCellNode)?.textField
    }

    var recipientsIndexPath: IndexPath {
        IndexPath(row: Elements.emailRecipients.rawValue, section: 0)
    }

    func attributedEmail(with string: String) -> NSAttributedString {
        string.attributed(.bold(13), alignment: .center)
    }

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
        node.reloadRows(at: [recipientsIndexPath], with: .fade)
        textField?.reset()
    }

    private func handleBackspaceAction(with textField: UITextField) {
        guard textField.text == "" else { return }

        let selectedRecipients = recipients
            .filter { $0.isSelected }

        guard selectedRecipients.isEmpty else {
            // remove selected recipients
            recipients = recipients
                .filter { !$0.isSelected }
            node.reloadRows(at: [recipientsIndexPath], with: .fade)
            return
        }

        if let lastRecipient = recipients.popLast() {
            // select last recipient in a list
            var last = lastRecipient
            last.isSelected = true
            recipients.append(last)
            node.reloadRows(at: [recipientsIndexPath], with: .fade)
        } else {
            // dismiss keyboard if no recipients left
            textField.resignFirstResponder()
        }
    }
}
