//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import Promises
import AsyncDisplayKit

final class ComposeViewController: ASViewController<ASTableNode> {
    enum Parts: Int, CaseIterable {
        case recipient, recipientDivider, subject, subjectDivider, text
    }

    struct Input {
        static let empty = Input(isReply: false, replyToRecipient: nil, replyToSubject: nil, replyToMime: nil)

        let isReply: Bool
        let replyToRecipient: MCOAddress?
        let replyToSubject: String?
        let replyToMime: Data?
    }

    private let imap: Imap
    private let notificationCenter: NotificationCenter
    private let dataManager: DataManagerType
    private let attesterApi: AttesterApiType
    private let storageService: StorageServiceType
    private var viewModel: Input

    init(
        imap: Imap = .instance,
        notificationCenter: NotificationCenter = .default,
        dataManager: DataManagerType = DataManager.shared,
        attesterApi: AttesterApiType = AttesterApi.shared,
        storageService: StorageServiceType = StorageService(),
        input: ComposeViewController.Input = .empty
    ) {
        self.imap = imap
        self.notificationCenter = notificationCenter
        self.dataManager = dataManager
        self.attesterApi = attesterApi
        self.viewModel = input
        self.storageService = storageService
        
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
            .map { UIEdgeInsets(top: 0, left: 0, bottom: $0 + 5, right: 0) }
            .subscribe(onNext: { [weak self] inset in
                self?.adjustForKeyboard(with: inset)
            })
    }

    @objc private func adjustForKeyboard(with inset: UIEdgeInsets) {
        //                self?.node.contentInset = inset
        //                self?.node.scrollToRow(at: IndexPath(item: Parts.passPhrase.rawValue, section: 0), at: .middle, animated: true)



//        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
//
//        if notification.name == UIResponder.keyboardWillHideNotification {
//            scrollView.contentInset = UIEdgeInsets.zero
//        } else {
//            scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height, right: 0)
//        }
//
//        guard txtMessage.isFirstResponder else { return }
//        scrollView.scrollIndicatorInsets = txtMessage.contentInset
//
//        guard let selectedRange = txtMessage.selectedTextRange else { return }
//        let rect = txtMessage.caretRect(for: selectedRange.start)
//        scrollView.scrollRectToVisible(rect, animated: true)
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

extension ComposeViewController {
    private func sendMsgTapHandler() {
//        view.endEditing(true)
//
//        guard isInputValid(),
//            let email = txtRecipient.text,
//            let text = txtMessage.text
//        else { return }
//
//        let pgpText = "compose_missed_public".localized
//        let subject = viewModel.isReply
//            ? "Re: \(viewModel.replyToSubject ?? "(no subject)")"
//            : txtSubject.text ?? "(no subject)"
//        let message = viewModel.isReply
//            ? "compose_reply_successfull".localized
//            : "compose_sent".localized
//
//        showSpinner("sending_title".localized)
//
//        Promise<Void> { [weak self] in
//            guard let self = self else { return }
//            let lookupRes = try await(self.attesterApi.lookupEmail(email: email))
//            guard let recipientPubkey = lookupRes.armored else { return self.showAlert(message: pgpText) }
//            let realm = try Realm() // TODO: Anton - Refactor to use db service
//
//            guard let myPubkey = realm.objects(KeyInfo.self).map({ $0.public }).first else { return self.showAlert(message: pgpText) }
//            let encrypted = self.encryptMsg(pubkeys: [myPubkey, recipientPubkey], subject: subject, message: text, email: email)
//            try await(self.imap.sendMail(mime: encrypted.mimeEncoded))
//        }.then(on: .main) { [weak self] in
//            self?.hideSpinner()
//            self?.showToast(message)
//            self?.navigationController?.popViewController(animated: true)
//        }.catch(on: .main) { [weak self] error in
//            self?.showAlert(error: error, message: "compose_error".localized)
//        }
    }

    private func encryptMsg(pubkeys: [String], subject: String, message: String, email: String) -> CoreRes.ComposeEmail {
        let replyToMimeMsg = viewModel.replyToMime
            .flatMap { String(data: $0, encoding: .utf8) }
        let msg = SendableMsg(
            text: message,
            to: [email],
            cc: [],
            bcc: [],
            from: dataManager.currentUser()?.email ?? "",
            subject: subject,
            replyToMimeMsg: replyToMimeMsg,
            atts: []
        )
        return try! Core.composeEmail(msg: msg, fmt: MsgFmt.encryptInline, pubKeys: pubkeys)
    }

    private func isInputValid() -> Bool {
//        guard txtRecipient.text?.hasContent ?? false else {
//            showAlert(message: "compose_enter_recipient".localized)
//            return false
//        }
//        guard viewModel.isReply || txtSubject.text?.hasContent ?? false else {
//            showAlert(message: "compose_enter_subject".localized)
//            return false
//        }
//        guard txtMessage.text?.hasContent ?? false else {
//            showAlert(message: "compose_enter_secure".localized)
//            return false
//        }
        return true
    }
}

// MARK: - UITextViewDelegate, UITextFieldDelegate

extension ComposeViewController: UITextViewDelegate, UITextFieldDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
//        let placeholder = "message_compose_secure".localized
//
//        if textView.text == "message_your".localized || textView.text == placeholder {
//            txtMessage.textColor = .black
//            txtMessage.text = ""
//        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
//        if textView.text == "" || textView.text == "\n" {
//            txtMessage.textColor = UIColor.lightGray
//            txtMessage.text = "message_your".localized
//        }
    }
}

// MARK: - Handle actions

extension ComposeViewController: ASTableDelegate, ASTableDataSource {

    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        return Parts.allCases.count
    }

    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self = self, let part = Parts(rawValue: indexPath.row) else { return ASCellNode() }
            switch part {
            case .recipientDivider, .subjectDivider: return DividerNode()
            case .recipient: return self.recipientNode()
            case .subject: return self.subjectNode()
            case .text: return self.textNode()
            }
        }
    }

    private func recipientNode() -> ASCellNode {
        let decorator = ComposeDecorator()
        let placeholder = decorator.styledPlaceholder("compose_recipient".localized)
        let node = TextFieldCellNode(placeholder)
        node.isLowercased = true
        node.shouldReturn = { [weak self] _ in
            guard let node = self?.node.visibleNodes[safe: Parts.subject.rawValue] as? TextFieldCellNode else { return true }
            node.firstResponder()
            return true
        }
        if viewModel.isReply {
            let title = viewModel.replyToRecipient?.mailbox ?? ""
            node.attributedText = decorator.styledTitle(title)
        }
        return node
    }

    private func subjectNode() -> ASCellNode {
        let decorator = ComposeDecorator()
        let placeholder = decorator.styledPlaceholder("compose_subject".localized)
        let node = TextFieldCellNode(placeholder)
        node.shouldReturn = { [weak self] _ in
            guard let self = self else { return true }
            if !self.viewModel.isReply, let node = self.node.visibleNodes.compactMap ({ $0 as? TextViewCellNode }).first {
                node.firstResponder()
            } else {
                self.node.view.endEditing(true)
            }
    
            return true
        }

        if viewModel.isReply {
            let title = "Re: \(viewModel.replyToSubject ?? "(no subject)")"
            node.attributedText = decorator.styledTitle(title)
        }
        return node
    }

    private func textNode() -> ASCellNode {
        return TextViewCellNode()
    }
}

struct ComposeDecorator {
    var styledPlaceholder: (String) -> TextFieldCellNode.Input {
        return {
            TextFieldCellNode.Input(
                placeholder: $0.localized.attributed(.regular(17), color: .lightGray, alignment: .left),
                isSecureTextEntry: false,
                textInsets: -7,
                textAlignment: .left
            )
        }
    }

    var styledTitle: (String) -> (NSAttributedString) {
        return { string in
            string.attributed(.regular(17))
        }
    }
}


final class TextViewCellNode: CellNode {
    enum TextViewActionType {
        case didEndEditing(String)
        case didBeginEditing(String)
    }

    typealias TextViewAction = (TextViewActionType) -> Void

    private let textView = ASEditableTextNode()

    override init() {
        super.init()

    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        textView.style.preferredSize.height = 300
        return ASInsetLayoutSpec(insets: UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8), child: textView)
    }

    func firstResponder() {
        textView.becomeFirstResponder()
    }
}
