//
//  EmailProviderViewController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 29/03/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptUI

final class EmailProviderViewController: ASViewController<TableNode> {
    enum Section {
        case account(AccountPart)
        case imap(ServerPart)
        case smtp(ServerPart)
        case other(OtherSMTP)
        case connect

        static let numberOfSections: Int = 5

        static func numberOfItems(for section: Int, state: State) -> Int {
            switch (section, state) {
            case (0, _):
                return AccountPart.allCases.count
            case (1, _), (2, _):
                return ServerPart.allCases.count
            case (3, .idle):
                return 1
            case (3, .extended):
                return OtherSMTP.allCases.count
            case (4, _):
                return 1
            default:
                return 0
            }
        }

        var section: Int {
            switch self {
            case .account: return 0
            case .imap: return 1
            case .smtp: return 2
            case .other: return 3
            case .connect: return 4
            }
        }


        init?(indexPath: IndexPath) {
            switch indexPath.section {
            case 0:
                guard let part = AccountPart(rawValue: indexPath.row) else { return nil }
                self = .account(part)
            case 1:
                guard let part = ServerPart(rawValue: indexPath.row) else { return nil }
                self = .imap(part)
            case 2:
                guard let part = ServerPart(rawValue: indexPath.row) else { return nil }
                self = .smtp(part)
            case 3:
                guard let part = OtherSMTP(rawValue: indexPath.row) else { return nil }
                self = .other(part)
            case 4:
                self = .connect
            default:
                return nil
            }
        }
    }

    enum AccountPart: Int, CaseIterable {
        case title, email, username, password
    }

    enum ServerPart: Int, CaseIterable {
        case title, server, port, security
    }

    enum OtherSMTP: Int, CaseIterable {
        case title, name, password
    }

    enum State: Equatable {
        case idle, extended
    }

    private var state: State = .idle
    private var selectedSection: Section?

    private let decorator: EmailProviderViewDecoratorType
    private let sessionCredentials: SessionCredentialsProvider
    private var user = UserObject.empty

    init(
        decorator: EmailProviderViewDecoratorType = EmailProviderViewDecorator(),
        sessionCredentials: SessionCredentialsProvider = SessionCredentialsService()
    ) {
        self.decorator = decorator
        self.sessionCredentials = sessionCredentials
        
        super.init(node: TableNode())
        node.delegate = self
        node.dataSource = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Setup
extension EmailProviderViewController {
    private func setupUI() {
        title = "Email Provider"
        observeKeyboardNotifications()
    }

    private func observeKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main) { [weak self] notification in
                guard let self = self else { return }
                self.adjustForKeyboard(height: self.keyboardHeight(from: notification))
            }

        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main) { [weak self] notification in
                self?.adjustForKeyboard(height: 0)
            }
    }

    private func adjustForKeyboard(height: CGFloat) {
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: height + 5, right: 0)
        node.contentInset = insets
        // TODO: ANTON -
//        node.scrollToRow(at: IndexPath(item: Parts.passPhrase.rawValue, section: 0), at: .middle, animated: true)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        node.reloadData()
    }

    private func update(for newState: State) {
        state = newState

        node.reloadSections(
            IndexSet(arrayLiteral: 3),
            with: .fade
        )

        node.scrollToRow(
            at: IndexPath(row: 2, section: 3),
            at: .bottom,
            animated: true
        )
    }
}

// MARK: - ASTableDelegate, ASTableDataSource
extension EmailProviderViewController: ASTableDelegate, ASTableDataSource {
    func numberOfSections(in tableNode: ASTableNode) -> Int {
        Section.numberOfSections
    }

    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        Section.numberOfItems(for: section, state: state)
    }

    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        { [weak self] in
            guard let self = self, let section = Section(indexPath: indexPath) else { return ASCellNode() }

            switch section {
            case .account(.title): return self.titleNode(for: indexPath)
            case .imap(.title): return self.titleNode(for: indexPath)
            case .smtp(.title): return self.titleNode(for: indexPath)
            case .other(.title): return self.switchNode()
            case .connect: return self.buttonNode()
            default: return self.textFieldNode(for: indexPath)
            }
        }
    }
}

// MARK: - Nodes
extension EmailProviderViewController {
    private func titleNode(for indexPath: IndexPath) -> ASCellNode {
        guard let section = Section(indexPath: indexPath) else {
            assertionFailure()
            return ASCellNode()
        }

        let input = decorator.title(for: section)
        
        return InfoCellNode(input: input)
    }

    private func textFieldNode(for indexPath: IndexPath) -> ASCellNode {
        guard let section = Section(indexPath: indexPath),
            let input = decorator.textFieldInput(for: section)
        else { assertionFailure(); return ASCellNode() }

        return TextFieldCellNode(input: input) { [weak self] action in
            self?.handleTextField(action, for: indexPath)
        }.then {
            $0.textField.attributedText = self.decorator.stringFor(user: self.user, for: section)
            self.setPicker(for: section, and: $0)
        }
    }

    private func switchNode() -> SwitchCellNode {
        SwitchCellNode(input: decorator.switchInput(isOn: state == .extended)) { isOn in
            let newState: State = isOn
                ? .extended
                : .idle
            self.update(for: newState)
        }
    }

    private func buttonNode() -> ButtonCellNode {
        ButtonCellNode(
            title: "other_provider_connect"
                .localized
                .attributed(.bold(20), color: .white, alignment: .center),
            insets: UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 10)
        ) { [weak self] in
            self?.handleConnect()
        }
    }
}

// MARK: - Helpers
extension EmailProviderViewController {
    private var connections: [ConnectionType] {
        ConnectionType.allCases
    }

    private var userNameIndexPath: IndexPath {
        IndexPath(row: AccountPart.username.rawValue, section: Section.account(.username).section)
    }

    private func reloadSessionCredentials() {
        node.reloadSections(
            IndexSet(integersIn: Section.imap(.port).section...Section.smtp(.port).section),
            with: .none
        )
    }

    private func setPicker(for section: Section, and node: TextFieldCellNode) {
        DispatchQueue.main.async {
            self.selectedSection = section
            node.textField.setPicker(view: self.decorator.pickerView(for: section, delegate: self, dataSource: self))
        }
    }
}

// MARK: - Actions
extension EmailProviderViewController {
    private func handleConnect() {

    }

    private func handleTextField(_ action: TextFieldActionType, for indexPath: IndexPath) {
        guard let section = Section(indexPath: indexPath) else { return }

        switch (section, action) {
        case (.account(.email), .editingChanged(let email)):
            updateForEmailChanges(with: email)
        case (.imap(.security), .didEndEditing):
            node.reloadRows(
                at: [IndexPath(row: ServerPart.security.rawValue, section: Section.imap(.security).section)],
                with: .none
            )
        case (.smtp(.security), .didEndEditing):
            node.reloadRows(
                at: [IndexPath(row: ServerPart.security.rawValue, section: Section.smtp(.security).section)],
                with: .none
            )

//        case .account(.password):
//        case .account(.username):
//        case .imap(.port):
//        case .imap(.server):
//        case .imap(.security):
        default: break
        }
    }

    private func updateForEmailChanges(with text: String?) {
        guard let email = text, email.isNotEmpty else {
            user = UserObject.empty
            node.reloadData()
            return
        }

        let parts = email.split(separator: "@").map(String.init)

        if let username = parts.first {
            user.name = username
            node.reloadRows(at: [userNameIndexPath], with: .none)
        }

        guard let provider = parts[safe: 1] else { return }

        let providerParts = provider.split(separator: ".").map(String.init)
        guard providerParts.count > 1 else {
            user.imap = .empty
            user.smtp = .empty
            reloadSessionCredentials()
            return
        }

        if let imap = sessionCredentials.getImapCredentials(for: email) {
            user.imap?.port = imap.port
            user.imap?.connectionType = imap.connectionType.rawValue
            user.imap?.hostname = imap.hostName ?? ""
        } else {
            user.imap?.connectionType = ConnectionType.tls.rawValue
            user.imap?.hostname = "imap.\(provider)"
        }
        if let smtp = sessionCredentials.getSmtpCredentials(for: email) {
            user.smtp?.port = smtp.port
            user.smtp?.connectionType = smtp.connectionType.rawValue
            user.smtp?.hostname = smtp.hostName ?? ""
        } else {
            user.smtp?.connectionType = ConnectionType.tls.rawValue
            user.smtp?.hostname = "smtp.\(provider)"
        }

        reloadSessionCredentials()
    }

}

extension EmailProviderViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        ConnectionType.allCases.count
    }

    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        connections[row].rawValue.attributed()
    }

    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        50
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch selectedSection {
        case .imap(.security):
            user.imap?.connectionType = connections[row].rawValue
        case .smtp(.security):
            user.smtp?.connectionType = connections[row].rawValue
        default:
            return
        }
    }
}
