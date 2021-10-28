//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit
import Combine
import FlowCryptCommon
import FlowCryptUI
import Foundation

/**
 * View controller to compose the message and send it
 * - User can be redirected here from *InboxViewController* by tapping on *+*
 * - Or from *MessageViewController* controller by tapping on *reply*
 **/

// swiftlint:disable file_length
private struct ComposedDraft: Equatable {
    let email: String
    let input: ComposeMessageInput
    let contextToSend: ComposeMessageContext
}

final class ComposeViewController: TableNodeViewController {
    private enum Constants {
        static let endTypingCharacters = [",", " ", "\n", ";"]
        static let shouldShowScopeAlertIndex = "indexShould_ShowScope"
    }

    enum State {
        case main, searchEmails([String])
    }

    private enum RecipientParts: Int, CaseIterable {
        case recipient, recipientsInput, recipientDivider
    }

    private enum ComposeParts: Int, CaseIterable {
        case subject, subjectDivider, text
    }

    private let composeMessageService: ComposeMessageService
    private let notificationCenter: NotificationCenter
    private let decorator: ComposeViewDecorator
    private let contactsService: ContactsServiceType
    private let filesManager: FilesManagerType
    private let photosManager: PhotosManagerType
    private let keyService: KeyServiceType
    private let service: ServiceActor
    private let passPhraseService: PassPhraseService

    private let search = PassthroughSubject<String, Never>()
    private let userDefaults: UserDefaults

    private let email: String

    private var cancellable = Set<AnyCancellable>()
    private var input: ComposeMessageInput
    private var contextToSend = ComposeMessageContext()

    private var state: State = .main

    private weak var saveDraftTimer: Timer?
    private var composedLatestDraft: ComposedDraft?

    init(
        email: String,
        notificationCenter: NotificationCenter = .default,
        decorator: ComposeViewDecorator = ComposeViewDecorator(),
        input: ComposeMessageInput = .empty,
        cloudContactProvider: CloudContactsProvider = UserContactsProvider(),
        userDefaults: UserDefaults = .standard,
        contactsService: ContactsServiceType = ContactsService(),
        composeMessageService: ComposeMessageService = ComposeMessageService(),
        filesManager: FilesManagerType = FilesManager(),
        photosManager: PhotosManagerType = PhotosManager(),
        keyService: KeyServiceType = KeyService(),
        passPhraseService: PassPhraseService = PassPhraseService()
    ) {
        self.email = email
        self.notificationCenter = notificationCenter
        self.input = input
        self.decorator = decorator
        self.userDefaults = userDefaults
        self.contactsService = contactsService
        self.composeMessageService = composeMessageService
        self.filesManager = filesManager
        self.photosManager = photosManager
        self.keyService = keyService
        self.service = ServiceActor(
            composeMessageService: composeMessageService,
            contactsService: contactsService,
            cloudContactProvider: cloudContactProvider
        )
        self.passPhraseService = passPhraseService
        self.contextToSend.subject = input.subject
        super.init(node: TableNode())
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupNavigationBar()
        observeKeyboardNotifications()
        observerAppStates()
        setupReply()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        node.view.endEditing(true)
        stopTimer()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showScopeAlertIfNeeded()
        cancellable.forEach { $0.cancel() }
        setupSearch()
        startTimer()

        evaluateIfNeeded()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func evaluateIfNeeded() {
        guard contextToSend.recipients.isNotEmpty else {
            return
        }

        for recepient in contextToSend.recipients {
            evaluate(recipient: recepient)
        }
    }

    func updateWithMessage(message: Message) {
        self.contextToSend.subject = message.subject
        self.contextToSend.message = message.raw
        self.contextToSend.recipients = [ComposeMessageRecipient(email: "tom@flowcrypt.com", state: decorator.recipientIdleState)]
    }

}

// MARK: - Drafts
extension ComposeViewController {
    @objc private func startTimer() {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            self.saveDraftTimer = Timer.scheduledTimer(
                timeInterval: 1,
                target: self,
                selector: #selector(self.saveDraftIfNeeded),
                userInfo: nil,
                repeats: true)
            self.saveDraftTimer?.fire()
        }
    }

    @objc private func stopTimer() {
        saveDraftTimer?.invalidate()
        saveDraftTimer = nil

        saveDraftIfNeeded()
    }

    private func shouldSaveDraft() -> Bool {
        let newDraft = ComposedDraft(email: email, input: input, contextToSend: contextToSend)

        guard let oldDraft = composedLatestDraft else {
            composedLatestDraft = newDraft
            return true
        }

        let result = newDraft != oldDraft
        composedLatestDraft = newDraft
        return result
    }

    @objc private func saveDraftIfNeeded() {
        Task {
            guard shouldSaveDraft() else { return }
            do {
                let signingPrv = try await prepareSigningKey()
                let messagevalidationResult = composeMessageService.validateMessage(
                    input: input,
                    contextToSend: contextToSend,
                    email: email,
                    includeAttachments: false,
                    signingPrv: signingPrv
                )
                guard case let .success(message) = messagevalidationResult else {
                    return
                }
                try await composeMessageService.encryptAndSaveDraft(message: message, threadId: input.threadId)
            } catch {}
        }
    }
}

// MARK: - Setup UI

extension ComposeViewController {
    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = NavigationBarItemsView(
            with: [
                NavigationBarItemsView.Input(
                    image: UIImage(named: "help_icn"),
                    action: (self, #selector(handleInfoTap))
                ),
                NavigationBarItemsView.Input(
                    image: UIImage(named: "paperclip"),
                    action: (self, #selector(handleAttachTap))
                ),
                NavigationBarItemsView.Input(
                    image: UIImage(named: "android-send"),
                    action: (self, #selector(handleSendTap)),
                    accessibilityLabel: "send"
                )
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

    private func setupReply() {
        guard input.isReply, let email = input.recipientReplyTitle else { return }

        let recipient = ComposeMessageRecipient(email: email, state: decorator.recipientIdleState)
        contextToSend.recipients.append(recipient)
        evaluate(recipient: recipient)
    }
}

// MARK: - Search
extension ComposeViewController {
    private func setupSearch() {
        search
            .debounce(for: .milliseconds(400), scheduler: RunLoop.main)
            .removeDuplicates()
            .compactMap { [weak self] in
                guard $0.isNotEmpty else {
                    self?.updateState(with: .main)
                    return nil
                }
                return $0
            }
            .sink { [weak self] in self?.searchEmail(with: $0) }
            .store(in: &cancellable)
    }
}

// MARK: - Keyboard

extension ComposeViewController {
    private func observeKeyboardNotifications() {
        // swiftlint:disable discarded_notification_center_observer
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
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

    private func observerAppStates() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(startTimer),
            name: UIApplication.didBecomeActiveNotification,
            object: nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(stopTimer),
            name: UIApplication.willResignActiveNotification,
            object: nil)
    }

    private func adjustForKeyboard(height: CGFloat) {
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: height + 8, right: 0)
        node.contentInset = insets

        guard let textView = node.visibleNodes.compactMap({ $0 as? TextViewCellNode }).first?.textView.textView else { return }
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
        openAttachmentsInputSourcesSheet()
    }

    @objc private func handleSendTap() {
        Task {
            do {
                let key = try await prepareSigningKey()
                sendMessage(key)
            } catch {}
        }
    }
}

// MARK: - Message Sending

extension ComposeViewController {
    private func prepareSigningKey() async throws -> PrvKeyInfo {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<PrvKeyInfo, Error>) in
            guard let signingKey = try? keyService.getSigningKey() else {
                let message = "No available private key has your user id \"\(email)\" in it. Please import the appropriate private key."
                showAlert(message: message)
                continuation.resume(throwing: MessageServiceError.unknown)
                return
            }

            guard let passphrase = signingKey.passphrase else {
                let alert = AlertsFactory.makePassPhraseAlert(
                    onCancel: { [weak self] in
                        self?.showAlert(message: "Passphrase is required for message signing")
                        continuation.resume(throwing: MessageServiceError.unknown)
                    },
                    onCompletion: { [weak self] passPhrase in
                        // save passphrase
                        let keyInfo = signingKey.copy(with: passPhrase)
                        self?.savePassPhrases(value: passPhrase, with: [keyInfo])
                        continuation.resume(returning: keyInfo)
                    })
                present(alert, animated: true, completion: nil)
                return
            }
            continuation.resume(returning: signingKey.copy(with: passphrase))
        }
    }

    private func savePassPhrases(value passPhrase: String, with privateKeys: [PrvKeyInfo]) {
        privateKeys
            .map { PassPhrase(value: passPhrase, fingerprints: $0.fingerprints) }
            .forEach { self.passPhraseService.savePassPhrase(with: $0, storageMethod: .memory) }
    }

    private func sendMessage(_ signingKey: PrvKeyInfo) {
        view.endEditing(true)
        navigationItem.rightBarButtonItem?.isEnabled = false

        let spinnerTitle = contextToSend.attachments.isEmpty ? "sending_title" : "encrypting_title"
        showSpinner(spinnerTitle.localized)

        let selectedRecipients = contextToSend.recipients.filter(\.state.isSelected)
        selectedRecipients.forEach(evaluate)

        // TODO: - fix for spinner
        // https://github.com/FlowCrypt/flowcrypt-ios/issues/291
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            let result = self.composeMessageService.validateMessage(
                input: self.input,
                contextToSend: self.contextToSend,
                email: self.email,
                signingPrv: signingKey
            )
            switch result {
            case .success(let message):
                self.encryptAndSend(message)
            case .failure(let error):
                self.handle(error: error)
            }
        }
    }

    private func encryptAndSend(_ message: SendableMsg) {
        Task {
            do {
                try await service.encryptAndSend(message: message,
                                                 threadId: input.threadId,
                                                 progressHandler: { [weak self] progress in
                    self?.updateSpinner(progress: progress)
                })
                handleSuccessfullySentMessage()
            } catch {
                if let error = error as? ComposeMessageError {
                    handle(error: error)
                }
            }
        }
    }

    private func handle(error: ComposeMessageError) {
        hideSpinner()
        navigationItem.rightBarButtonItem?.isEnabled = true

        let message = "compose_error".localized
            + "\n\n"
            + error.description

        showAlert(message: message)
    }

    private func handleSuccessfullySentMessage() {
        hideSpinner()
        navigationItem.rightBarButtonItem?.isEnabled = true
        showToast(input.successfullySentToast)
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - ASTableDelegate, ASTableDataSource

extension ComposeViewController: ASTableDelegate, ASTableDataSource {
    func numberOfSections(in _: ASTableNode) -> Int {
        3
    }

    func tableNode(_: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        switch (state, section) {
        case (.main, 0):
            return RecipientParts.allCases.count
        case (.main, 1):
            return ComposeParts.allCases.count
        case (.main, 2):
            return contextToSend.attachments.count
        case (.searchEmails, 0):
            return RecipientParts.allCases.count
        case let (.searchEmails(emails), 1):
            return emails.count
        default:
            return 0
        }
    }

    // swiftlint:disable cyclomatic_complexity
    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self = self else { return ASCellNode() }

            switch (self.state, indexPath.section) {
            case (_, 0):
                guard let part = RecipientParts(rawValue: indexPath.row) else { return ASCellNode() }
                switch part {
                case .recipientDivider: return DividerCellNode()
                case .recipientsInput: return self.recipientInput()
                case .recipient: return self.recipientsNode()
                }
            case (.main, 1):
                guard let composePart = ComposeParts(rawValue: indexPath.row) else { return ASCellNode() }
                switch composePart {
                case .subject: return self.subjectNode()
                case .text: return self.textNode()
                case .subjectDivider: return DividerCellNode()
                }
            case (.main, 2):
                guard !self.contextToSend.attachments.isEmpty else {
                    return ASCellNode()
                }
                return self.attachmentNode(for: indexPath.row)
            case let (.searchEmails(emails), 1):
                return InfoCellNode(input: self.decorator.styledRecipientInfo(with: emails[indexPath.row]))
            default:
                return ASCellNode()
                
            }
        }
    }

    func tableNode(_: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        guard case let .searchEmails(emails) = state,
            indexPath.section == 1,
            let selectedEmail = emails[safe: indexPath.row]
        else { return }

        handleEndEditingAction(with: selectedEmail)
    }
}

// MARK: - Nodes

extension ComposeViewController {
    private func subjectNode() -> ASCellNode {
        TextFieldCellNode(
            input: decorator.styledTextFieldInput(with: "compose_subject".localized)
        ) { [weak self] event in
            switch event {
            case .editingChanged(let text), .didEndEditing(let text):
                self?.contextToSend.subject = text
            case .didBeginEditing, .deleteBackward:
                return
            }
        }
        .onShouldReturn { [weak self] _ in
            guard let self = self else { return true }
            if !self.input.isReply, let node = self.node.visibleNodes.compactMap({ $0 as? TextViewCellNode }).first {
                node.becomeFirstResponder()
            } else {
                self.node.view.endEditing(true)
            }
            return true
        }
        .then {
            let subject = input.isReply ? input.subjectReplyTitle : contextToSend.subject
            $0.attributedText = decorator.styledTitle(with: subject)
        }
    }

    private func textNode() -> ASCellNode {
        let replyQuote = decorator.styledReplyQuote(with: input)
        let height = max(decorator.frame(for: replyQuote).height, 40)

        return TextViewCellNode(
            decorator.styledTextViewInput(with: height)
        ) { [weak self] event in
            switch event {
            case .editingChanged(let text), .didEndEditing(let text):
                self?.contextToSend.message = text?.string
            case .didBeginEditing:
                break
            }
        }
        .then {
            let messageText = decorator.styledMessage(with: contextToSend.message ?? "")

            if input.isReply && !messageText.string.contains(replyQuote.string) {
                let mutableString = NSMutableAttributedString(attributedString: messageText)
                mutableString.append(replyQuote)
                $0.textView.attributedText = mutableString
                $0.becomeFirstResponder()
            } else {
                $0.textView.attributedText = messageText
            }
        }
    }

    private func recipientsNode() -> RecipientEmailsCellNode {
        RecipientEmailsCellNode(recipients: recipients.map(RecipientEmailsCellNode.Input.init))
            .onItemSelect { [weak self] (action: RecipientEmailsCellNode.RecipientEmailTapAction) in
                switch action {
                case let .imageTap(indexPath): self?.handleRecipientAction(with: indexPath)
                case let .select(indexPath): self?.handleRecipientSelection(with: indexPath)
                }
            }
    }

    private func recipientInput() -> TextFieldCellNode {
        TextFieldCellNode(
            input: decorator.styledTextFieldInput(with: "compose_recipient".localized, keyboardType: .emailAddress)
        ) { [weak self] action in
            self?.handleTextFieldAction(with: action)
        }
        .onShouldReturn { textField -> Bool in
            textField.resignFirstResponder()
            return true
        }
        .onShouldChangeCharacters { [weak self] textField, character -> (Bool) in
            self?.shouldChange(with: textField, and: character) ?? true
        }
        .then {
            $0.isLowercased = true
            if !self.input.isReply {
                $0.becomeFirstResponder()
            }
        }
    }

    private func attachmentNode(for index: Int) -> ASCellNode {
        AttachmentNode(
            input: .init(
                composeAttachment: contextToSend.attachments[index]
            ),
            onDeleteTap: { [weak self] in
                self?.contextToSend.attachments.safeRemove(at: index)
                self?.node.reloadSections(IndexSet(integer: 2), with: .automatic)
            }
        )
    }
}

// MARK: - Recipients Input
extension ComposeViewController {
    private var textField: TextFieldNode? {
        (node.nodeForRow(at: IndexPath(row: RecipientParts.recipientsInput.rawValue, section: 0)) as? TextFieldCellNode)?.textField
    }

    private var recipientsIndexPath: IndexPath {
        IndexPath(row: RecipientParts.recipient.rawValue, section: 0)
    }

    private var recipients: [ComposeMessageRecipient] {
        contextToSend.recipients
    }

    private func shouldChange(with textField: UITextField, and character: String) -> Bool {
        func nextResponder() {
            guard let node = node.visibleNodes[safe: ComposeParts.subject.rawValue] as? TextFieldCellNode else { return }
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
        case let .deleteBackward(textField): handleBackspaceAction(with: textField)
        case let .didEndEditing(text): handleEndEditingAction(with: text)
        case let .editingChanged(text): handleEditingChanged(with: text)
        case .didBeginEditing: handleDidBeginEditing()
        }
    }

    private func handleEndEditingAction(with text: String?) {
        guard let text = text, text.isNotEmpty else { return }

        // Set all recipients to idle state
        contextToSend.recipients = recipients.map { recipient in
            var recipient = recipient
            if recipient.state.isSelected {
                recipient.state = self.decorator.recipientIdleState
            }
            return recipient
        }

        let newRecipient = ComposeMessageRecipient(email: text, state: decorator.recipientIdleState)
        let indexOfRecipient: Int

        if let index = contextToSend.recipients.firstIndex(where: { $0.email == newRecipient.email }) {
            // recipient already in list
            evaluate(recipient: newRecipient)
            indexOfRecipient = index
        } else {
            // add new recipient
            contextToSend.recipients.append(newRecipient)
            node.reloadRows(at: [recipientsIndexPath], with: .fade)
            evaluate(recipient: newRecipient)

            // scroll to the latest recipient
            indexOfRecipient = recipients.endIndex - 1
        }

        let collectionNode = (node.nodeForRow(at: recipientsIndexPath) as? RecipientEmailsCellNode)?.collectionNode
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            collectionNode?.scrollToItem(
                at: IndexPath(row: indexOfRecipient, section: 0),
                at: .bottom,
                animated: true
            )
        }

        // reset textfield
        textField?.reset()
        node.view.keyboardDismissMode = .interactive

        updateState(with: .main)
    }

    private func handleBackspaceAction(with textField: UITextField) {
        guard textField.text == "" else { return }

        let selectedRecipients = recipients
            .filter { $0.state.isSelected }

        guard selectedRecipients.isEmpty else {
            // remove selected recipients
            contextToSend.recipients = recipients.filter { !$0.state.isSelected }
            node.reloadRows(at: [recipientsIndexPath], with: .fade)
            return
        }

        if let lastRecipient = contextToSend.recipients.popLast() {
            // select last recipient in a list
            var last = lastRecipient
            last.state = self.decorator.recipientSelectedState
            contextToSend.recipients.append(last)
            node.reloadRows(at: [recipientsIndexPath], with: .fade)
        } else {
            // dismiss keyboard if no recipients left
            textField.resignFirstResponder()
        }
    }

    private func handleEditingChanged(with text: String?) {
        guard let text = text, text.isNotEmpty else {
            search.send("")
            return
        }

        search.send(text)
    }

    private func handleDidBeginEditing() {
        node.view.keyboardDismissMode = .none
    }
}

// MARK: - Action Handling
extension ComposeViewController {
    private func searchEmail(with query: String) {
        Task {
            let localEmails = contactsService.searchContacts(query: query)
            let cloudEmails = try? await service.searchContacts(query: query)
            let emails = Set([localEmails, cloudEmails].compactMap { $0 }.flatMap { $0 })
            let state: State = emails.isNotEmpty
                ? .searchEmails(Array(emails))
                : .main
            updateState(with: state)
        }
    }

    private func evaluate(recipient: ComposeMessageRecipient) {
        guard recipient.email.isValidEmail else {
            handleEvaluation(for: recipient, with: self.decorator.recipientInvalidEmailState)
            return
        }

        Task {
            do {
                let contact = try await service.searchContact(with: recipient.email)
                let state = getRecipientState(from: contact)
                handleEvaluation(for: recipient, with: state)
            } catch {
                handleEvaluation(error: error, with: recipient)
            }
        }
    }

    private func getRecipientState(from recipient: RecipientWithSortedPubKeys) -> RecipientState {
        switch recipient.keyState {
        case .active:
            return decorator.recipientKeyFoundState
        case .expired:
            return decorator.recipientKeyExpiredState
        case .revoked:
            return decorator.recipientKeyRevokedState
        case .empty:
            return decorator.recipientKeyNotFoundState
        }
    }

    private func handleEvaluation(for recipient: ComposeMessageRecipient, with state: RecipientState) {
        updateRecipientWithNew(
            state: state,
            for: .left(recipient)
        )
    }

    private func handleEvaluation(error: Error, with recipient: ComposeMessageRecipient) {
        let recipientState: RecipientState = {
            switch error {
            case ContactsError.keyMissing:
                return self.decorator.recipientKeyNotFoundState
            default:
                return self.decorator.recipientErrorStateRetry
            }
        }()

        updateRecipientWithNew(
            state: recipientState,
            for: .left(recipient)
        )
    }

    private func updateRecipientWithNew(state: RecipientState, for context: Either<ComposeMessageRecipient, IndexPath>) {
        let index: Int? = {
            switch context {
            case let .left(recipient):
                guard let index = recipients.firstIndex(where: { $0.email == recipient.email }) else {
                    assertionFailure()
                    return nil
                }
                return index
            case let .right(index):
                return index.row
            }
        }()

        guard let recipientIndex = index else { return }
        contextToSend.recipients[recipientIndex].state = state
        node.reloadRows(at: [recipientsIndexPath], with: .fade)
    }

    private func handleRecipientSelection(with indexPath: IndexPath) {
        var recipient = contextToSend.recipients[indexPath.row]

        if recipient.state.isSelected {
            recipient.state = decorator.recipientIdleState
            contextToSend.recipients[indexPath.row].state = decorator.recipientIdleState
            evaluate(recipient: recipient)
        } else {
            contextToSend.recipients[indexPath.row].state = decorator.recipientSelectedState
        }

        node.reloadRows(at: [recipientsIndexPath], with: .fade)
        if !(textField?.isFirstResponder() ?? true) {
            textField?.becomeFirstResponder()
        }
        textField?.reset()
    }

    private func handleRecipientAction(with indexPath: IndexPath) {
        let recipient = contextToSend.recipients[indexPath.row]
        switch recipient.state {
        case .idle:
            handleRecipientSelection(with: indexPath)
        case .keyFound, .keyExpired, .keyRevoked, .keyNotFound, .invalidEmail, .selected:
            break
        case let .error(_, isRetryError):
            if isRetryError {
                updateRecipientWithNew(state: decorator.recipientIdleState, for: .right(indexPath))
                evaluate(recipient: recipient)
            } else {
                contextToSend.recipients.remove(at: indexPath.row)
                node.reloadRows(at: [recipientsIndexPath], with: .fade)
            }
        }
    }
}

// MARK: - State Handling
extension ComposeViewController {
    private func updateState(with newState: State) {
        state = newState

        node.reloadSections([1], with: .automatic)

        switch state {
        case .main:
            node.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
        case .searchEmails:
            break
        }
    }
}

// MARK: - UIDocumentPickerDelegate
extension ComposeViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let fileUrl = urls.first,
              let attachment = ComposeMessageAttachment(fileURL: fileUrl)
        else {
            showAlert(message: "files_picking_files_error_message".localized)
            return
        }
        appendAttachmentIfAllowed(attachment)
        node.reloadSections(IndexSet(integer: 2), with: .automatic)
    }
}

// MARK: - UIImagePickerControllerDelegate & UINavigationControllerDelegate
extension ComposeViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        picker.dismiss(animated: true, completion: nil)

        let composeMessageAttachment: ComposeMessageAttachment?
        switch picker.sourceType {
        case .camera:
            composeMessageAttachment = ComposeMessageAttachment(cameraSourceMediaInfo: info)
        case .photoLibrary:
            composeMessageAttachment = ComposeMessageAttachment(librarySourceMediaInfo: info)
        default: fatalError("No other image picker's sources should be used")
        }
        guard let attachment = composeMessageAttachment else {
            showAlert(message: "files_picking_photos_error_message".localized)
            return
        }
        appendAttachmentIfAllowed(attachment)
        node.reloadSections(IndexSet(integer: 2), with: .automatic)
    }

    private func appendAttachmentIfAllowed(_ attachment: ComposeMessageAttachment) {
        let totalSize = contextToSend.attachments.reduce(0, { $0 + $1.size }) + attachment.size
        if totalSize > GeneralConstants.Global.attachmentSizeLimit {
            showToast("files_picking_size_error_message".localized)
        } else {
            contextToSend.attachments.append(attachment)
        }
    }
}

// MARK: - Attachments sheet handling
extension ComposeViewController {
    private func openAttachmentsInputSourcesSheet() {
        let alert = UIAlertController(
            title: "files_picking_select_input_source_title".localized,
            message: nil, preferredStyle: .actionSheet
        )
        alert.addAction(
            UIAlertAction(
                title: "files_picking_camera_input_source".localized,
                style: .default,
                handler: { [weak self] _ in
                    guard let self = self else { return }
                    self.photosManager.selectPhoto(source: .camera, from: self)
                        .sinkFuture(
                            receiveValue: {},
                            receiveError: { _ in
                                self.showNoAccessToPhotosAlert()
                            }
                        )
                        .store(in: &self.cancellable)
                }
            )
        )
        alert.addAction(
            UIAlertAction(
                title: "files_picking_photo_library_source".localized,
                style: .default,
                handler: { [weak self] _ in
                    guard let self = self else { return }
                    self.photosManager.selectPhoto(source: .photoLibrary, from: self)
                        .sinkFuture(
                            receiveValue: {},
                            receiveError: { _ in
                                self.showNoAccessToPhotosAlert()
                            }
                        )
                        .store(in: &self.cancellable)
                }
            )
        )
        alert.addAction(
            UIAlertAction(
                title: "files_picking_files_source".localized,
                style: .default,
                handler: { [weak self] _ in
                    guard let self = self else { return }
                    self.filesManager.selectFromFilesApp(from: self)
                }
            )
        )
        alert.addAction(UIAlertAction(title: "cancel".localized, style: .cancel))
        present(alert, animated: true, completion: nil)
    }

    private func showNoAccessToPhotosAlert() {
        let alert = UIAlertController(
            title: "files_picking_no_library_access_error_title".localized,
            message: "files_picking_no_library_access_error_message".localized,
            preferredStyle: .alert
        )
        let okAction = UIAlertAction(
            title: "OK",
            style: .cancel
        ) { _ in }
        let settingsAction = UIAlertAction(
            title: "settings".localized,
            style: .default
        ) { _ in
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
        }
        alert.addAction(okAction)
        alert.addAction(settingsAction)

        present(alert, animated: true, completion: nil)
    }
}

extension ComposeViewController {
    private func showScopeAlertIfNeeded() {
        if shouldRenewToken(for: [.mail]),
            !userDefaults.bool(forKey: Constants.shouldShowScopeAlertIndex) {
            userDefaults.set(true, forKey: Constants.shouldShowScopeAlertIndex)
            let alert = UIAlertController(
                title: "",
                message: "compose_enable_search".localized,
                preferredStyle: .alert
            )
            let okAction = UIAlertAction(
                title: "Log out",
                style: .default
            ) { _ in }
            let cancelAction = UIAlertAction(
                title: "cancel".localized,
                style: .destructive
            ) { _ in }
            alert.addAction(okAction)
            alert.addAction(cancelAction)

            present(alert, animated: true, completion: nil)
        }
    }

    private func shouldRenewToken(for newScope: [GoogleScope]) -> Bool {
        false
    }
}

// TODO temporary solution for background execution problem
private actor ServiceActor {
    private let composeMessageService: ComposeMessageService
    private let contactsService: ContactsServiceType
    private let cloudContactProvider: CloudContactsProvider

    init(composeMessageService: ComposeMessageService,
         contactsService: ContactsServiceType,
         cloudContactProvider: CloudContactsProvider) {
        self.composeMessageService = composeMessageService
        self.contactsService = contactsService
        self.cloudContactProvider = cloudContactProvider
    }

    func encryptAndSend(message: SendableMsg, threadId: String?, progressHandler: ((Float) -> Void)?) async throws {
        try await composeMessageService.encryptAndSend(message: message,
                                                       threadId: threadId,
                                                       progressHandler: progressHandler)
    }

    func searchContacts(query: String) async throws -> [String] {
        return try await cloudContactProvider.searchContacts(query: query)
    }

    func searchContact(with email: String) async throws -> RecipientWithSortedPubKeys {
        return try await contactsService.searchContact(with: email)
    }
}
