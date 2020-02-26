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
            contextToSend.recipient = input.recipientReplyTitle
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

    deinit {
        NotificationCenter.default.removeObserver(self)
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
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: height + 8, right: 0)
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
            guard let email = self.contextToSend.recipient, let text = self.contextToSend.message else {
                assertionFailure("Text and Email should not be nil at this point. Fail in checking");
                return false
            }
            let subject = self.input.subjectReplyTitle ?? self.contextToSend.subject ?? "(no subject)"
            let lookupRes = try await(self.attesterApi.lookupEmail(email: email))
            guard let recipientPubkey = lookupRes.armored else {
                self.showAlert(message: "compose_no_pub_recipient".localized)
                return false
            }
            guard let myPubkey = self.dataManager.publicKey() else {
                self.showAlert(message: "compose_no_pub_sender".localized)
                return false
            }
            let encrypted = self.encryptMsg(
                pubkeys: [myPubkey, recipientPubkey],
                subject: subject,
                message: text,
                email: email
            )
            try await(self.imap.sendMail(mime: encrypted.mimeEncoded))
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
        guard contextToSend.recipient?.hasContent ?? false else {
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
            case .recipientDivider, .subjectDivider: return DividerCellNode()
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
            self?.contextToSend.recipient = text
        }
        .onReturn { [weak self] _ in
            guard let node = self?.node.visibleNodes[safe: Parts.subject.rawValue] as? TextFieldCellNode else { return true }
            node.becomeFirstResponder()
            return true
        }
        .then {
            $0.isLowercased = true
            $0.attributedText = decorator.styledTitle(input.recipientReplyTitle)
            if !self.input.isReply {
                $0.becomeFirstResponder()
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
        .onReturn { [weak self] _ in
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
        let prefferedHeight = nodeHeight - 2 * (textFieldHeight + dividerHeight)

        return TextViewCellNode(decorator.styledTextViewInput(with: prefferedHeight)) { [weak self] event in
            guard case let .didEndEditing(text) = event else { return }
            self?.contextToSend.message = text?.string
        }.then {
            if self.input.isReply {
                $0.becomeFirstResponder()
            }
        }
    }
}
