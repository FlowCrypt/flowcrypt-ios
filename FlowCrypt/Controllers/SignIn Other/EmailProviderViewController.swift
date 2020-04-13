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

        var indexPath: IndexPath {
            switch self {
            case .account(.username): return IndexPath(row: AccountPart.username.rawValue, section: 0)
            default: assertionFailure("Not implemented"); return IndexPath(row: 0, section: 0)
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
            $0.textField.attributedText = self.userDataFor(section: section)
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
            title: "Connect".attributed(.bold(20), color: .textColor, alignment: .center),
            insets: UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 10)
        ) { [weak self] in
            self?.handleConnect()
        }
    }
}

// MARK: - Actions
extension EmailProviderViewController {
    private func handleConnect() {

    }

    private func handleTextField(_ action: TextFieldActionType, for indexPath: IndexPath) {
        guard let section = Section(indexPath: indexPath) else { return }

        switch section {
        case .account(.email): handle(email: action)
//        case .account(.password):
//        case .account(.username):
//        case .imap(.port):
//        case .imap(.server):
//        case .imap(.security):
        default: break
        }
    }

    private func handle(email action: TextFieldActionType) {
        switch action {
        case let .editingChanged(text):
            guard let email = text, email.isNotEmpty else {
                user.name = ""
                node.reloadRows(at: [Section.account(.username).indexPath], with: .fade)
                return
            }

            let parts = email.split(separator: "@").map(String.init)

            if let username = parts.first {
                user.name = username
                node.reloadRows(at: [Section.account(.username).indexPath], with: .fade)
            }

            // username@email.com
            // 1 - username, 2 - email, 3 - com
            guard let provider = parts[safe: 1] else { return }

            let providerParts = provider.split(separator: ".").map(String.init)
            guard providerParts.count > 1 else { return }

            if let imap = sessionCredentials.getImapCredentials(for: email) {
                user.imap?.port = imap.port
                node.reloadSections(IndexSet(integer: 1), with: .fade)
            }
            if let smtp = sessionCredentials.getSmtpCredentials(for: email) {

            }

//            if let imap =
//            sessionCredentials.getImapCredentials(for: email)
        default:
            break
        }
    }

    private func userDataFor(section: Section) -> NSAttributedString? {
        switch section {
        case .account(.username):
            if user.name.isEmpty {
                return nil
            }
            return NSAttributedString(string: self.user.name)
        case .imap(.port):
            if let port = user.imap?.port, port != UserObject.empty.imap?.port {
                return "\(port)".attributed()
            }
            return nil
        default:
            return nil
        }
    }
}
