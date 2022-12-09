//
//  SetupImapViewController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 29/03/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptUI

/**
 * Controller that gives a possibility for the user to enter information about his email provider like, account, imap/smtp information
 * - User redirects here from SignInViewController
 * - After successful connection user will be redirected to *setup flow* which would typically means *SetupInitialViewController*
 */
final class SetupImapViewController: TableNodeViewController {
    private enum UserError: Error {
        case password
        case empty
        case email
    }

    private var state: State = .idle
    private var selectedSection: Section?

    private let appContext: AppContext
    private let decorator: SetupImapViewDecorator
    private let sessionCredentials: SessionCredentialsProviderType
    private let imap: Imap
    private var user = User.empty

    init(
        appContext: AppContext,
        decorator: SetupImapViewDecorator = SetupImapViewDecorator(),
        sessionCredentials: SessionCredentialsProviderType = SessionCredentialsProvider(),
        imap: Imap = Imap(user: User.empty)
    ) {
        self.appContext = appContext
        self.decorator = decorator
        self.sessionCredentials = sessionCredentials
        self.imap = imap

        super.init(node: TableNode())
        node.delegate = self
        node.dataSource = self
    }

    @available(*, unavailable)
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

// MARK: - Parts
extension SetupImapViewController {
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

        var indexPath: IndexPath {
            let row: Int
            switch self {
            case let .account(part): row = part.rawValue
            case let .imap(part): row = part.rawValue
            case let .smtp(part): row = part.rawValue
            case let .other(part): row = part.rawValue
            case .connect: row = 0
            }
            return IndexPath(row: row, section: self.section)
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
}

// MARK: - Setup
extension SetupImapViewController {
    private func setupUI() {
        title = "setup_providers".localized
        observeKeyboardNotifications()
    }

    // swiftlint:disable discarded_notification_center_observer
    private func observeKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self else { return }
            self.adjustForKeyboard(height: self.keyboardHeight(from: notification))
        }

        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.adjustForKeyboard(height: 0)
        }
    }

    private func adjustForKeyboard(height: CGFloat) {
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: height + 5, right: 0)
        node.contentInset = insets
    }

    private func update(for newState: State) {
        state = newState

        node.reloadSections([3], with: .fade)

        node.scrollToRow(
            at: IndexPath(row: 2, section: 3),
            at: .bottom,
            animated: true
        )
    }
}

// MARK: - ASTableDelegate, ASTableDataSource
extension SetupImapViewController: ASTableDelegate, ASTableDataSource {
    func numberOfSections(in tableNode: ASTableNode) -> Int {
        Section.numberOfSections
    }

    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        Section.numberOfItems(for: section, state: state)
    }

    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock { { [weak self] in
        guard let self, let section = Section(indexPath: indexPath) else { return ASCellNode() }

        switch section {
        case .account(.title):
            return self.titleNode(for: indexPath)
        case .imap(.title):
            return self.titleNode(for: indexPath)
        case .smtp(.title):
            return self.titleNode(for: indexPath)
        case .other(.title):
            return self.switchNode()
        case .connect:
            return self.buttonNode()
        default:
            return self.textFieldNode(for: indexPath)
        }
    }
    }
}

// MARK: - Nodes
extension SetupImapViewController {
    private func titleNode(for indexPath: IndexPath) -> ASCellNode {
        guard let section = Section(indexPath: indexPath) else {
            assertionFailure()
            return ASCellNode()
        }
        return InfoCellNode(
            input: decorator.title(for: section)
        )
    }

    private func textFieldNode(for indexPath: IndexPath) -> ASCellNode {
        guard let section = Section(indexPath: indexPath),
              let input = decorator.textFieldInput(for: section)
        else { assertionFailure(); return ASCellNode() }

        return TextFieldCellNode(input: input) { [weak self] action in
            self?.handleTextField(action, for: indexPath)
        }
        .onShouldReturn { [weak self] _ in
            self?.textFieldShouldReturn() ?? true
        }
        .then {
            $0.textField.attributedText = self.decorator.stringFor(user: self.user, for: section)
            $0.textField.autocapitalizationType = .none
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
        let input = ButtonCellNode.Input(
            title: decorator.connectButtonTitle
        )
        let node = ButtonCellNode(input: input) { [weak self] in
            self?.connect()
        }
        node.accessibilityIdentifier = "aid-connect-button"
        return node
    }
}

// MARK: - Helpers
extension SetupImapViewController {
    private var connections: [ConnectionType] {
        ConnectionType.allCases
    }

    private var userNameIndexPath: IndexPath {
        IndexPath(row: AccountPart.username.rawValue, section: Section.account(.username).section)
    }

    private func reloadImapSection() {
        node.reloadSections(
            [Section.imap(.port).section],
            with: .none
        )
    }

    private func reloadSmtpSection() {
        node.reloadSections(
            [Section.smtp(.port).section],
            with: .none
        )
    }

    private func reloadSessionCredentials() {
        node.reloadSections(
            IndexSet(integersIn: Section.imap(.port).section ... Section.smtp(.port).section),
            with: .none
        )
    }

    private func setPicker(for section: Section, and node: TextFieldCellNode) {
        DispatchQueue.main.async {
            if let picker = self.decorator.pickerView(for: section, delegate: self, dataSource: self) {
                node.textField.setPicker(view: picker) {
                    self.textFieldShouldReturn()
                }
            }
            if self.decorator.shouldAddToolBar(for: section) {
                node.textField.setToolbar {
                    self.textFieldShouldReturn()
                }
            }
        }
    }
}

// MARK: - Actions
extension SetupImapViewController {
    private func handleTextField(_ action: TextFieldActionType, for indexPath: IndexPath) {
        guard let section = Section(indexPath: indexPath) else { return }
        selectedSection = section

        switch (section, action) {
        case let (.account(.email), .editingChanged(email)):
            updateForEmailChanges(with: email)
        case let (.account(.password), .didEndEditing(password)):
            user.imap?.password = password
            user.smtp?.password = password
        case (.imap(.security), .didBeginEditing):
            user.imap?.connectionType = connections[0].rawValue
        case (.imap(.security), .didEndEditing):
            updateUserImapCredentials()
            reloadImapSection()
        case (.smtp(.security), .didBeginEditing):
            user.smtp?.connectionType = connections[0].rawValue
        case (.smtp(.security), .didEndEditing):
            updateUserSmtpCredentials()
            reloadSmtpSection()
        case let (.other(.name), .didEndEditing(name)):
            user.smtp?.username = name ?? user.name
        case let (.other(.password), .didEndEditing(password)):
            user.smtp?.password = password ?? user.password
        default: break
        }
    }

    private func updateForEmailChanges(with text: String?) {
        guard let email = text, email.isNotEmpty else {
            user = User.empty
            node.reloadData()
            return
        }
        user.email = email

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

        if let imapSetting = sessionCredentials.getImapCredentials(for: email) {
            updateUser(imap: imapSetting)
        } else {
            user.imap?.connectionType = ConnectionType.tls.rawValue
            user.imap?.hostname = "imap.\(provider)"
            updateUserImapCredentials()
        }

        if let smtpSetting = sessionCredentials.getSmtpCredentials(for: email) {
            updateUser(smtp: smtpSetting)
        } else {
            user.smtp?.connectionType = ConnectionType.tls.rawValue
            user.smtp?.hostname = "smtp.\(provider)"
            updateUserSmtpCredentials()
        }

        reloadSessionCredentials()
    }

    private func updateUserImapCredentials() {
        guard let connectionType = ConnectionType(rawValue: user.imap?.connectionType ?? "") else {
            reloadSessionCredentials()
            return
        }
        let settings = sessionCredentials.imapFor(connection: connectionType, email: user.email)

        switch settings {
        case let .failure(.notFound(defaultPort)):
            let port = user.imap?.port ?? defaultPort
            user.imap?.port = port
        case let .success(imapSetting):
            updateUser(imap: imapSetting)
        }
    }

    private func updateUserSmtpCredentials() {
        guard let connectionType = ConnectionType(rawValue: user.smtp?.connectionType ?? "") else {
            reloadSessionCredentials()
            return
        }
        let settings = sessionCredentials.smtpFor(connection: connectionType, email: user.email)

        switch settings {
        case let .failure(.notFound(defaultPort)):
            let port = user.smtp?.port ?? defaultPort
            user.smtp?.port = port
        case let .success(imapSetting):
            updateUser(smtp: imapSetting)
        }
    }

    private func updateUser(imap settings: MailSettingsCredentials) {
        user.imap?.port = settings.port
        user.imap?.connectionType = settings.connectionType.rawValue
        user.imap?.hostname = settings.hostName ?? ""
    }

    private func updateUser(smtp settings: MailSettingsCredentials) {
        user.smtp?.port = settings.port
        user.smtp?.connectionType = settings.connectionType.rawValue
        user.smtp?.hostname = settings.hostName ?? ""
    }

    @discardableResult
    private func textFieldShouldReturn() -> Bool {
        guard let selectedSection else {
            assertionFailure("Check selected section property")
            view.endEditing(true)
            return true
        }

        let currentIndexPath = selectedSection.indexPath
        let numberOfRowsInSelectedSection = node.numberOfRows(inSection: currentIndexPath.section)
        let nextIndexPath: IndexPath = {
            let nextRow = currentIndexPath.row + 1
            if nextRow < numberOfRowsInSelectedSection {
                let next = IndexPath(row: nextRow, section: currentIndexPath.section)
                return next
            } else {
                let next = IndexPath(row: 1, section: currentIndexPath.section + 1)
                return next
            }
        }()

        guard let nextTextField = node.nodeForRow(at: nextIndexPath) as? TextFieldCellNode else {
            view.endEditing(true)
            return true
        }

        DispatchQueue.main.async {
            nextTextField.becomeFirstResponder()
        }

        return true
    }
}

// MARK: - Connect
extension SetupImapViewController {
    private func connect() {
        view.endEditing(true)

        do {
            try checkCurrentUser()
            checkImapSession()
        } catch {
            switch error as? UserError {
            case .empty:
                showToast("other_provider_error_other".localized)
            case .password:
                showToast("other_provider_error_password".localized)
            case .email:
                showToast("other_provider_error_email".localized)
            default:
                break
            }
        }
    }

    private func checkImapSession() {
        showSpinner()

        Task {
            do {
                let imapSessionToCheck = try IMAPSession(user: user)
                let smtpSession = try SMTPSession(user: user)
                try await self.imap.connectImap(session: imapSessionToCheck)
                try await self.imap.connectSmtp(session: smtpSession)
                handleSuccessfulConnection()
            } catch {
                handleConnection(error: error)
            }
        }
    }

    private func handleConnection(error: Error) {
        showAlert(error: error, message: "error_connection".localized)
    }

    private func handleSuccessfulConnection() {
        hideSpinner()
        Task {
            await appContext.globalRouter.signIn(
                appContext: self.appContext,
                route: .other(.session(user)),
                email: nil
            )
        }
    }

    private func checkCurrentUser() throws {
        guard user != User.empty, user.email != User.empty.email else {
            throw UserError.empty
        }

        guard let password = user.password, password.isNotEmpty else {
            throw UserError.password
        }
    }
}

// MARK: - Picker
extension SetupImapViewController: UIPickerViewDelegate, UIPickerViewDataSource {
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
