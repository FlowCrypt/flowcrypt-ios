//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import Promises
import AsyncDisplayKit
import FlowCryptUI

final class ComposeViewController: ASViewController<TableNode> {
    struct Input {
        static let empty = Input(isReply: false, replyToRecipient: nil, replyToSubject: nil, replyToMime: nil)

        let isReply: Bool
        let replyToRecipient: MCOAddress?
        let replyToSubject: String?
        let replyToMime: Data?

        var recipientReplyTitle: String? {
            isReply ? replyToRecipient?.mailbox : nil
        }

        var subjectReplyTitle: String? {
            isReply ? "Re: \(replyToSubject ?? "(no subject)")" : nil
        }

        var successfullySentToast: String {
            isReply ? "compose_reply_successfull".localized : "compose_sent".localized
        }
    }

    struct Recipient {
        let email: String
        var isSelected: Bool

        init(
            email: String,
            isSelected: Bool = false
        ) {
            self.email = email
            self.isSelected = isSelected
        }
    }

    private struct Context {
        var message: String?
        var recipients: [Recipient] = []
        var subject: String?
    }
    
    private enum Constants {
        static let endTypingCharacters = [",", " ", "\n", ";"]
    }

    private enum Parts: Int, CaseIterable {
        case recipient, recipientsInput, recipientDivider, subject, subjectDivider, text
    }

    private let imap: Imap
    private let notificationCenter: NotificationCenter
    private let dataManager: DataManagerType
    private let attesterApi: AttesterApiType
    private let decorator: ComposeDecoratorType
    private let core: Core

    private var input: Input
    private var contextToSend = Context()

    init(
        imap: Imap = Imap.shared,
        notificationCenter: NotificationCenter = .default,
        dataManager: DataManagerType = DataManager.shared,
        attesterApi: AttesterApiType = AttesterApi.shared,
        decorator: ComposeDecoratorType = ComposeDecorator(),
        input: ComposeViewController.Input = .empty,
        core: Core = Core.shared
    ) {
        self.imap = imap
        self.notificationCenter = notificationCenter
        self.dataManager = dataManager
        self.attesterApi = attesterApi
        self.input = input
        self.decorator = decorator
        self.core = core
        if input.isReply {
            if let email = input.recipientReplyTitle {
                contextToSend.recipients.append(Recipient(email: email))
            }
            contextToSend.subject = input.replyToSubject
        }
        super.init(node: TableNode())
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupNavigationBar()
        observeKeyboardNotifications()

        // establish session before user taps send, so that sending msg is faster once the user does tap it
        imap.getSmtpSess()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        node.view.endEditing(true)
    }
}

// MARK: - Setup UI

extension ComposeViewController {
    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = NavigationBarItemsView(
            with: [
                NavigationBarItemsView.Input(image: UIImage(named: "help_icn"), action: (self, #selector(handleInfoTap))),
                NavigationBarItemsView.Input(image: UIImage(named: "paperclip"), action: (self, #selector(handleAttachTap))),
                NavigationBarItemsView.Input(image: UIImage(named: "android-send"), action: (self, #selector(handleSendTap)), accessibilityLabel: "send"),
            ]
        )
    }

    private func setupUI() {
        node.do {
            $0.delegate = self
            $0.dataSource = self
            $0.view.keyboardDismissMode = .interactive
        }
    }
}

// MARK: - Keyboard

extension ComposeViewController {
    private func observeKeyboardNotifications() {
        _ = keyboardHeight
            .map { UIEdgeInsets(top: 0, left: 0, bottom: $0 + 8, right: 0) }
            .subscribe(onNext: {  [weak self] insets in
                self?.adjustForKeyboard(insets: insets)
            })
    }

    @objc private func adjustForKeyboard(insets: UIEdgeInsets) {
        node.contentInset = insets

        guard let textView = node.visibleNodes.compactMap ({ $0 as? TextViewCellNode }).first?.textView.textView else { return }
        guard let selectedRange = textView.selectedTextRange else { return }
        let rect = textView.caretRect(for: selectedRange.start)
        node.view.scrollRectToVisible(rect, animated: true)
    }
}

// MARK: - Handle actions

extension ComposeViewController {
    @objc private func handleInfoTap() {
        #warning("ToDo")
        showToast("Please email us at human@flowcrypt.com for help")
    }

    @objc private func handleAttachTap() {
        #warning("ToDo")
        showToast("Attachments not implemented yet")
    }

    @objc private func handleSendTap() {
        sendMsgTapHandler()
    }
}

// MARK: - Message Sending

extension ComposeViewController {
    private func sendMsgTapHandler() {
        view.endEditing(true)
        guard isInputValid() else { return }

        showSpinner("sending_title".localized)

        Promise<Bool> { [weak self] in
            return try await(self!.encryptAndSendMessage())
        }.then(on: .main) { [weak self] sent in
            if sent { // else it must have shown error to user
                self?.handleSuccessfullySentMessage()
            }
        }.catch(on: .main) { [weak self] error in
            self?.showAlert(error: error, message: "compose_error".localized)
        }
    }

    private func encryptAndSendMessage() -> Promise<Bool> {
        Promise<Bool> { [weak self] () -> Bool in
            guard let self = self else { return false }

            guard self.contextToSend.recipients.isNotEmpty else {
                assertionFailure("Recipients should not be empty. Fail in checking");
                return false
            }

            guard let text = self.contextToSend.message else {
                assertionFailure("Text and Email should not be nil at this point. Fail in checking");
                return false
            }

            let subject = self.input.subjectReplyTitle
                ?? self.contextToSend.subject
                ?? "(no subject)"

            let lookup = self.contextToSend.recipients.map {
                self.attesterApi.lookupEmail(email: $0.email)
            }

            let lookupRes = try await(all(lookup))

            let armoredKeys = lookupRes.map { $0.armored }

            if armoredKeys.contains(nil) {
                self.showAlert(message: "compose_no_pub_recipient".localized)
                return false
            }

            guard let myPubkey = self.dataManager.publicKey() else {
                self.showAlert(message: "compose_no_pub_sender".localized)
                return false
            }

            let sentResult = lookupRes
                .compactMap { (searchResult: PubkeySearchResult) -> CoreRes.ComposeEmail? in
                    guard let armored = searchResult.armored else { assertionFailure(); return nil }
                    return self.encryptMsg(
                        pubkeys: [myPubkey, armored],
                        subject: subject,
                        message: text,
                        email: searchResult.email
                    )
                }
                .map { $0.mimeEncoded }
                .map { self.imap.sendMail(mime: $0) }

            _ = try await(all(sentResult))

            return true
        }
    }

    private func handleSuccessfullySentMessage() {
        hideSpinner()
        showToast(input.successfullySentToast)
        navigationController?.popViewController(animated: true)
    }

    private func encryptMsg(pubkeys: [String], subject: String, message: String, email: String) -> CoreRes.ComposeEmail {
        let replyToMimeMsg = input.replyToMime
            .flatMap { String(data: $0, encoding: .utf8) }
        let msg = SendableMsg(
            text: message,
            to: [email],
            cc: [],
            bcc: [],
            from: dataManager.email ?? "",
            subject: subject,
            replyToMimeMsg: replyToMimeMsg,
            atts: []
        )
        return try! core.composeEmail(msg: msg, fmt: MsgFmt.encryptInline, pubKeys: pubkeys)
    }

    private func isInputValid() -> Bool {
        let emails = recipients.map { $0.email }
        let hasContent = emails.filter { $0.hasContent }

        guard emails.count == hasContent.count else {
            showAlert(message: "compose_enter_recipient".localized)
            return false
        }
        guard input.isReply || contextToSend.subject?.hasContent ?? false else {
            showAlert(message: "compose_enter_subject".localized)
            return false
        }

        guard contextToSend.message?.hasContent ?? false else {
            showAlert(message: "compose_enter_secure".localized)
            return false
        }
        return true
    }
}


// MARK: - ASTableDelegate, ASTableDataSource

extension ComposeViewController: ASTableDelegate, ASTableDataSource {

    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        Parts.allCases.count
    }

    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        let nodeHeight = tableNode.frame.size.height
            - (navigationController?.navigationBar.frame.size.height ?? 0.0)
            - safeAreaWindowInsets.top
            - safeAreaWindowInsets.bottom
        return { [weak self] in
            guard let self = self, let part = Parts(rawValue: indexPath.row) else { return ASCellNode() }
            switch part {
            case .recipientDivider, .subjectDivider: return DividerCellNode()
            case .recipientsInput: return self.recipientInput()
            case .recipient: return self.recipientsNode()
            case .subject: return self.subjectNode()
            case .text: return self.textNode(with: nodeHeight)
            }
        }
    }

    private func subjectNode() -> ASCellNode {
        TextFieldCellNode(
            input: decorator.styledTextFieldInput("compose_subject".localized)
        ) { [weak self] event in
            guard case let .didEndEditing(text) = event else { return }
            self?.contextToSend.subject = text
        }
        .onShouldReturn { [weak self] _ in
            guard let self = self else { return true }
            if !self.input.isReply, let node = self.node.visibleNodes.compactMap ({ $0 as? TextViewCellNode }).first {
                node.becomeFirstResponder()
            } else {
                self.node.view.endEditing(true)
            }
            return true
        }
        .then {
            $0.attributedText = decorator.styledTitle(input.subjectReplyTitle)
        }
    }

    private func textNode(with nodeHeight: CGFloat) -> ASCellNode {
        let textFieldHeight = decorator.styledTextFieldInput("").height
        let dividerHeight: CGFloat = 1
        let preferredHeight = nodeHeight - 2 * (textFieldHeight + dividerHeight)

        return TextViewCellNode(decorator.styledTextViewInput(with: preferredHeight)) { [weak self] event in
            guard case let .didEndEditing(text) = event else { return }
            self?.contextToSend.message = text?.string
        }.then {
            if self.input.isReply {
                $0.becomeFirstResponder()
            }
        }
    }
}

// MARK: - Recipients
extension ComposeViewController {
    private var textField: TextFieldNode? {
        (node.nodeForRow(at: IndexPath(row: Parts.recipientsInput.rawValue, section: 0)) as? TextFieldCellNode)?.textField
    }

    private var recipientsIndexPath: IndexPath {
        IndexPath(row: Parts.recipient.rawValue, section: 0)
    }

    private func recipientsNode() -> RecipientEmailsCellNode {
        RecipientEmailsCellNode(recipients: recipients.map(RecipientEmailsCellNode.Input.init))
            .onItemSelect { [weak self] indexPath in
                self?.handleRecipientSelection(with: indexPath)
            }
    }

    private func recipientInput() -> TextFieldCellNode {
        TextFieldCellNode(
            input: decorator.styledTextFieldInput("compose_recipient".localized)
        ) { [weak self] action in
            self?.handleTextFieldAction(with: action)
        }
        .onShouldReturn { [weak self] textField -> Bool in
            self?.shouldReturn(with: textField) ?? true
        }
        .onShouldChangeCharacters { [weak self] (textField, character) -> (Bool) in
            self?.shouldChange(with: textField, and: character) ?? true
        }
        .then {
            $0.isLowercased = true
            if !self.input.isReply {
                $0.becomeFirstResponder()
            }
        }
    }

    private var recipients: [ComposeViewController.Recipient] {
        contextToSend.recipients
    }

    private func shouldReturn(with textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    private func shouldChange(with textField: UITextField, and character: String) -> Bool {
        func nextResponder() {
            guard let node = node.visibleNodes[safe: Parts.subject.rawValue] as? TextFieldCellNode else { return }
            node.becomeFirstResponder()
        }

        guard let text = textField.text else { nextResponder(); return true }

        if text.isEmpty, character.count > 1 {
            // Pasted string
            let characterSet = CharacterSet(charactersIn: Constants.endTypingCharacters.joined())
            let recipients = character.components(separatedBy: characterSet)
            guard recipients.count > 1 else { return true }
            recipients.forEach {
                handleEndEditingAction(with: $0)
            }
            return false
        } else if Constants.endTypingCharacters.contains(character) {
            handleEndEditingAction(with: textField.text)
            nextResponder()
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
        guard let text = text, text.isNotEmpty else { return }

        contextToSend.recipients = recipients.map { recipient in
            var recipient = recipient
            recipient.isSelected = false
            return recipient
        }
        contextToSend.recipients.append(Recipient(email: text))
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
            .filter { $0.isSelected }

        guard selectedRecipients.isEmpty else {
            // remove selected recipients
            contextToSend.recipients = recipients.filter { !$0.isSelected }
            node.reloadRows(at: [recipientsIndexPath], with: .fade)
            return
        }

        if let lastRecipient = contextToSend.recipients.popLast() {
            // select last recipient in a list
            var last = lastRecipient
            last.isSelected = true
            contextToSend.recipients.append(last)
            node.reloadRows(at: [recipientsIndexPath], with: .fade)
        } else {
            // dismiss keyboard if no recipients left
            textField.resignFirstResponder()
        }
    }

    private func handleRecipientSelection(with indexPath: IndexPath) {
        contextToSend.recipients[indexPath.row].isSelected.toggle()
        node.reloadRows(at: [recipientsIndexPath], with: .fade)
        if !(textField?.isFirstResponder() ?? true) {
            textField?.becomeFirstResponder()
        }
        textField?.reset()
    }
}
