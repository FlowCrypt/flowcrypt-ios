//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import Promises
import AsyncDisplayKit

final class ComposeViewController: ASViewController<TableNode> {
    private let imap: Imap
    private let notificationCenter: NotificationCenter
    private let dataManager: DataManagerType
    private let attesterApi: AttesterApiType
    private let storageService: EncryptedStorageType
    private let decorator: ComposeDecoratorType
    private let core: Core

    private var input: Input
    private var contextToSend = Context()

    init(
        imap: Imap = Imap(),
        notificationCenter: NotificationCenter = .default,
        dataManager: DataManagerType = DataManager(),
        attesterApi: AttesterApiType = AttesterApi.shared,
        storageService: EncryptedStorageType = EncryptedStorage(),
        decorator: ComposeDecoratorType = ComposeDecorator(),
        input: ComposeViewController.Input = .empty,
        core: Core = Core.shared
    ) {
        self.imap = imap
        self.notificationCenter = notificationCenter
        self.dataManager = dataManager
        self.attesterApi = attesterApi
        self.input = input
        self.storageService = storageService
        self.decorator = decorator
        self.core = core
        if input.isReply {
            contextToSend.resipient = input.recipientReplyTitle
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
                NavigationBarItemsView.Input(image: UIImage(named: "android-send"), action: (self, #selector(handleSendTap))),
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
        showToast("Email us at human@flowcrypt.com")
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

        Promise<Void> { [weak self] in
            try await(self!.sendMessage())
        }.then(on: .main) { [weak self] in
            self?.handleSuccessfullySentMessage()
        }.catch(on: .main) { [weak self] error in
            self?.showAlert(error: error, message: "compose_error".localized)
        }
    }

    private func sendMessage() -> Promise<Void> {
        Promise { [weak self] in
            guard let self = self else { return }
            guard let email = self.contextToSend.resipient, let text = self.contextToSend.message else {
                assertionFailure("Text and Email should not be nil at this point. Fail in checking");
                return
            }

            let subject = self.input.subjectReplyTitle
                ?? self.contextToSend.subject
                ?? "(no subject)"

            let lookupRes = try await(self.attesterApi.lookupEmail(email: email))

            guard let recipientPubkey = lookupRes.armored else {
                return self.showAlert(message: "compose_no_pub_recipient".localized)
            }

            guard let myPubkey = self.storageService.publicKey() else {
                return self.showAlert(message: "compose_no_pub_sender".localized)
            }

            let encrypted = self.encryptMsg(
                pubkeys: [myPubkey, recipientPubkey],
                subject: subject,
                message: text,
                email: email
            )
            try await(self.imap.sendMail(mime: encrypted.mimeEncoded))
        }
    }

    private func handleSuccessfullySentMessage() {
        hideSpinner()
        showToast(input.alertMessage)
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
        guard contextToSend.resipient?.hasContent ?? false else {
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
        return Parts.allCases.count
    }

    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        let nodeHeight = tableNode.frame.size.height
            - (navigationController?.navigationBar.frame.size.height ?? 0.0)
            - safeAreaWindowInsets.top
            - safeAreaWindowInsets.bottom
        return { [weak self] in
            guard let self = self, let part = Parts(rawValue: indexPath.row) else { return ASCellNode() }
            switch part {
            case .recipientDivider, .subjectDivider: return DividerNode()
            case .recipient: return self.recipientNode()
            case .subject: return self.subjectNode()
            case .text: return self.textNode(with: nodeHeight)
            }
        }
    }

    private func recipientNode() -> ASCellNode {
        TextFieldCellNode(
            input: decorator.styledTextFieldInput("compose_recipient".localized)
        ) { [weak self] event in
            guard case let .didEndEditing(text) = event else { return }
            self?.contextToSend.resipient = text
        }
        .onReturn { [weak self] _ in
            guard let node = self?.node.visibleNodes[safe: Parts.subject.rawValue] as? TextFieldCellNode else { return true }
            node.firstResponder()
            return true
        }
        .then {
            $0.isLowercased = true
            $0.attributedText = decorator.styledTitle(input.recipientReplyTitle)
        }
    }

    private func subjectNode() -> ASCellNode {
        TextFieldCellNode(
            input: decorator.styledTextFieldInput("compose_subject".localized)
        ) { [weak self] event in
            guard case let .didEndEditing(text) = event else { return }
            self?.contextToSend.subject = text
        }
        .onReturn { [weak self] _ in
            guard let self = self else { return true }
            if !self.input.isReply, let node = self.node.visibleNodes.compactMap ({ $0 as? TextViewCellNode }).first {
                node.firstResponder()
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
        let prefferedHeight = nodeHeight - 2 * (textFieldHeight + dividerHeight)

        return TextViewCellNode(decorator.styledTextViewInput(with: prefferedHeight)) { [weak self] event in
            guard case let .didEndEditing(text) = event else { return }
            self?.contextToSend.message = text?.string
        }
    }
}
