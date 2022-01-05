//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit
import Combine
import FlowCryptCommon
import FlowCryptUI
import Foundation
import PhotosUI

// swiftlint:disable file_length
private struct ComposedDraft: Equatable {
    let email: String
    let input: ComposeMessageInput
    let contextToSend: ComposeMessageContext
}

/**
 * View controller to compose the message and send it
 * - User can be redirected here from *InboxViewController* by tapping on *+*
 * - Or from *ThreadDetailsViewController* controller by tapping on *reply* or *forward*
 **/
final class ComposeViewController: TableNodeViewController {

    private enum Constants {
        static let endTypingCharacters = [",", " ", "\n", ";"]
    }

    enum State {
        case main, searchEmails([String])
    }

    private enum Section: Int, CaseIterable {
        case recipient, password, compose, attachments
    }

    private enum RecipientPart: Int, CaseIterable {
        case list, input
    }

    private enum ComposePart: Int, CaseIterable {
        case topDivider, subject, subjectDivider, text
    }

    private let appContext: AppContext
    private let composeMessageService: ComposeMessageService
    private let notificationCenter: NotificationCenter
    private let decorator: ComposeViewDecorator
    private let contactsService: ContactsServiceType
    private let cloudContactProvider: CloudContactsProvider
    private let filesManager: FilesManagerType
    private let photosManager: PhotosManagerType
    private let keyMethods: KeyMethodsType
    private let service: ServiceActor
    private let router: GlobalRouterType
    private let clientConfiguration: ClientConfiguration

    private let email: String
    private var isMessagePasswordSupported: Bool {
        guard let domain = email.emailParts?.domain else { return false }
        let senderDomainsWithMessagePasswordSupport = ["flowcrypt.com"]
        return senderDomainsWithMessagePasswordSupport.contains(domain)
    }

    private let search = PassthroughSubject<String, Never>()
    private var cancellable = Set<AnyCancellable>()

    private var input: ComposeMessageInput
    private var contextToSend = ComposeMessageContext()

    private var state: State = .main
    private var shouldEvaluateRecipientInput = true

    private weak var saveDraftTimer: Timer?
    private var composedLatestDraft: ComposedDraft?

    private var messagePasswordAlertController: UIAlertController?
    private var didLayoutSubviews = false
    private var topContentInset: CGFloat {
        navigationController?.navigationBar.frame.maxY ?? 0
    }

    init(
        appContext: AppContext,
        notificationCenter: NotificationCenter = .default,
        decorator: ComposeViewDecorator = ComposeViewDecorator(),
        input: ComposeMessageInput = .empty,
        cloudContactProvider: CloudContactsProvider? = nil,
        contactsService: ContactsServiceType? = nil,
        composeMessageService: ComposeMessageService? = nil,
        filesManager: FilesManagerType = FilesManager(),
        photosManager: PhotosManagerType = PhotosManager(),
        keyMethods: KeyMethodsType = KeyMethods()
    ) {
        self.appContext = appContext
        guard let email = appContext.dataService.email else {
            fatalError("missing current user email") // todo - need a more elegant solution
        }
        self.email = email
        self.notificationCenter = notificationCenter
        self.input = input
        self.decorator = decorator
        let clientConfiguration = appContext.clientConfigurationService.getSaved(for: email)
        self.contactsService = contactsService ?? ContactsService(
            localContactsProvider: LocalContactsProvider(
                encryptedStorage: appContext.encryptedStorage
            ),
            clientConfiguration: clientConfiguration
        )
        let cloudContactProvider = cloudContactProvider ?? UserContactsProvider(
            userService: GoogleUserService(
                currentUserEmail: email,
                appDelegateGoogleSessionContainer: UIApplication.shared.delegate as? AppDelegate
            )
        )
        self.cloudContactProvider = cloudContactProvider
        self.composeMessageService = composeMessageService ?? ComposeMessageService(
            clientConfiguration: clientConfiguration,
            encryptedStorage: appContext.encryptedStorage,
            messageGateway: appContext.getRequiredMailProvider().messageSender
        )
        self.filesManager = filesManager
        self.photosManager = photosManager
        self.keyMethods = keyMethods
        self.service = ServiceActor(
            composeMessageService: self.composeMessageService,
            contactsService: self.contactsService,
            cloudContactProvider: cloudContactProvider
        )
        self.router = appContext.globalRouter
        self.contextToSend.subject = input.subject
        self.contextToSend.attachments = input.attachments
        self.clientConfiguration = clientConfiguration
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
        observeComposeUpdates()
        setupQuote()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        node.view.endEditing(true)
        stopDraftTimer()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        startDraftTimer()

        guard shouldEvaluateRecipientInput else {
            shouldEvaluateRecipientInput = true
            return
        }

        cancellable.forEach { $0.cancel() }
        setupSearch()

        evaluateIfNeeded()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard !didLayoutSubviews else { return }

        didLayoutSubviews = true
        node.contentInset.top = topContentInset
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func evaluateIfNeeded() {
        guard contextToSend.recipients.isNotEmpty else {
            return
        }

        for recipient in contextToSend.recipients {
            evaluate(recipient: recipient)
        }
    }

    func update(with message: Message) {
        self.contextToSend.subject = message.subject
        self.contextToSend.message = message.raw
        self.contextToSend.recipients = [ComposeMessageRecipient(email: "tom@flowcrypt.com", state: decorator.recipientIdleState)]
    }

    private func observeComposeUpdates() {
        composeMessageService.onStateChanged { [weak self] state in
            DispatchQueue.main.async {
                self?.updateSpinner(with: state)
            }
        }
    }

    private func updateSpinner(with state: ComposeMessageService.State) {
        switch state {
        case .progressChanged(let progress):
            if progress < 1 {
                showProgressHUD(
                    progress: progress,
                    label: state.message ?? "\(progress)"
                )
            } else {
                showIndeterminateHUD(with: "sending_title".localized)
            }
        case .startComposing, .validatingMessage:
            showIndeterminateHUD(with: state.message ?? "")
        case .idle, .messageSent:
            hideSpinner()
        }
    }
}

// MARK: - Drafts
extension ComposeViewController {
    @objc private func startDraftTimer() {
        saveDraftTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.saveDraftIfNeeded()
        }
        saveDraftTimer?.fire()
    }

    @objc private func stopDraftTimer() {
        saveDraftTimer?.invalidate()
        saveDraftTimer = nil
        saveDraftIfNeeded()
    }

    private func shouldSaveDraft() -> Bool {
        // https://github.com/FlowCrypt/flowcrypt-ios/issues/975
        return false
//        let newDraft = ComposedDraft(email: email, input: input, contextToSend: contextToSend)
//        guard let oldDraft = composedLatestDraft else {
//            composedLatestDraft = newDraft
//            return true
//        }
//        let result = newDraft != oldDraft
//        composedLatestDraft = newDraft
//        return result
    }

    private func saveDraftIfNeeded() {
        guard shouldSaveDraft() else { return }
        Task {
            do {
                let signingPrv = try await prepareSigningKey()
                let sendableMsg = try await composeMessageService.validateAndProduceSendableMsg(
                    input: input,
                    contextToSend: contextToSend,
                    email: email,
                    includeAttachments: false,
                    signingPrv: signingPrv
                )
                try await composeMessageService.encryptAndSaveDraft(message: sendableMsg, threadId: input.threadId)
            } catch {
                if !(error is MessageValidationError) {
                    // no need to save or notify user if validation error
                    // for other errors show toast
                    // todo - should make sure that the toast doesn't hide the keyboard. Also should be toasted on top when keyboard open?
                    showToast("Error saving draft: \(error.errorMessage)")
                }
            }
        }
    }
}

// MARK: - Setup UI

extension ComposeViewController {
    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = NavigationBarItemsView(
            with: [
                NavigationBarItemsView.Input(
                    image: UIImage(named: "help_icn")
                ) { [weak self] in
                    self?.handleInfoTap()
                },
                NavigationBarItemsView.Input(
                    image: UIImage(named: "paperclip")
                ) { [weak self] in
                    self?.handleAttachTap()
                },
                NavigationBarItemsView.Input(
                    image: UIImage(named: "android-send"),
                    accessibilityId: "aid-compose-send"
                ) { [weak self] in
                    self?.handleSendTap()
                }
            ]
        )
    }

    private func setupUI() {
        node.do {
            $0.delegate = self
            $0.dataSource = self
            $0.view.contentInsetAdjustmentBehavior = .never
            $0.view.keyboardDismissMode = .interactive
        }
    }

    private func setupQuote() {
        guard input.isQuote else { return }

        input.quoteRecipients.forEach { email in
            let recipient = ComposeMessageRecipient(email: email, state: decorator.recipientIdleState)
            contextToSend.recipients.append(recipient)
            evaluate(recipient: recipient)
        }
    }
}

// MARK: - Search
extension ComposeViewController {
    private func setupSearch() {
        search
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .map { [weak self] query -> String in
                if query.isEmpty { self?.updateState(with: .main) }
                return query
            }
            .sink(receiveValue: { [weak self] in
                guard $0.isNotEmpty else { return }
                self?.searchEmail(with: $0)
            })
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
            selector: #selector(startDraftTimer),
            name: UIApplication.didBecomeActiveNotification,
            object: nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(stopDraftTimer),
            name: UIApplication.willResignActiveNotification,
            object: nil)
    }

    private func adjustForKeyboard(height: CGFloat) {
        node.contentInset.bottom = height + 8

        guard let textView = node.visibleNodes.compactMap({ $0 as? TextViewCellNode }).first?.textView.textView,
              let selectedRange = textView.selectedTextRange
        else { return }

        let rect = textView.caretRect(for: selectedRange.start)
        node.view.scrollRectToVisible(rect, animated: true)
    }
}

// MARK: - Handle actions

extension ComposeViewController {
    private func handleInfoTap() {
        showToast("Please email us at human@flowcrypt.com for help")
    }

    private func handleAttachTap() {
        openAttachmentsInputSourcesSheet()
    }

    private func handleSendTap() {
        Task {
            do {
                guard contextToSend.hasMessagePasswordIfNeeded else {
                    throw MessageValidationError.noPubRecipients
                }

                let key = try await prepareSigningKey()
                try await sendMessage(key)
            } catch {
                handle(error: error)
            }
        }
    }
}

// MARK: - Message Sending

extension ComposeViewController {
    private func prepareSigningKey() async throws -> PrvKeyInfo {
        guard let signingKey = try await appContext.keyService.getSigningKey() else {
            throw AppErr.general("None of your private keys have your user id \"\(email)\". Please import the appropriate key.")
        }

        guard let existingPassPhrase = signingKey.passphrase else {
            return signingKey.copy(with: try await self.requestMissingPassPhraseWithModal(for: signingKey))
        }

        return signingKey.copy(with: existingPassPhrase)
    }

    private func requestMissingPassPhraseWithModal(for signingKey: PrvKeyInfo) async throws -> String {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            let alert = AlertsFactory.makePassPhraseAlert(
                onCancel: {
                    return continuation.resume(throwing: AppErr.user("Passphrase is required for message signing"))
                },
                onCompletion: { [weak self] passPhrase in
                    guard let self = self else {
                        return continuation.resume(throwing: AppErr.nilSelf)
                    }
                    Task<Void, Never> {
                        do {
                            let matched = try await self.handlePassPhraseEntry(passPhrase, for: signingKey)
                            if matched {
                                return continuation.resume(returning: passPhrase)
                            } else {
                                throw AppErr.user("This pass phrase did not match your signing private key")
                            }
                        } catch {
                            return continuation.resume(throwing: error)
                        }
                    }
                }
            )
            present(alert, animated: true, completion: nil)
        }
    }

    private func handlePassPhraseEntry(_ passPhrase: String, for signingKey: PrvKeyInfo) async throws -> Bool {
        // since pass phrase was entered (an inconvenient thing for user to do),
        //  let's find all keys that match and save the pass phrase for all
        let allKeys = try await appContext.keyService.getPrvKeyInfo()
        guard allKeys.isNotEmpty else {
            // tom - todo - nonsensical error type choice https://github.com/FlowCrypt/flowcrypt-ios/issues/859
            //   I copied it from another usage, but has to be changed
            throw KeyServiceError.retrieve
        }
        let matchingKeys = try await self.keyMethods.filterByPassPhraseMatch(keys: allKeys, passPhrase: passPhrase)
        // save passphrase for all matching keys
        try appContext.passPhraseService.savePassPhrasesInMemory(passPhrase, for: matchingKeys)
        // now figure out if the pass phrase also matched the signing prv itself
        let matched = matchingKeys.first(where: { $0.fingerprints.first == signingKey.fingerprints.first })
        return matched != nil// true if the pass phrase matched signing key
    }

    private func sendMessage(_ signingKey: PrvKeyInfo) async throws {
        view.endEditing(true)
        navigationItem.rightBarButtonItem?.isEnabled = false

        let spinnerTitle = contextToSend.attachments.isEmpty ? "sending_title" : "encrypting_title"
        showSpinner(spinnerTitle.localized)

        let selectedRecipients = contextToSend.recipients.filter(\.state.isSelected)
        for selectedRecipient in selectedRecipients {
            evaluate(recipient: selectedRecipient)
        }

        // TODO: - fix for spinner
        // https://github.com/FlowCrypt/flowcrypt-ios/issues/291
        try await Task.sleep(nanoseconds: 100 * 1_000_000) // 100ms

        let sendableMsg = try await self.composeMessageService.validateAndProduceSendableMsg(
            input: self.input,
            contextToSend: self.contextToSend,
            email: self.email,
            signingPrv: signingKey,
            isMessagePasswordSupported: isMessagePasswordSupported
        )
        UIApplication.shared.isIdleTimerDisabled = true
        try await service.encryptAndSend(
            message: sendableMsg,
            threadId: input.threadId
        )
        handleSuccessfullySentMessage()
    }

    private func handle(error: Error) {
        UIApplication.shared.isIdleTimerDisabled = false
        hideSpinner()
        navigationItem.rightBarButtonItem?.isEnabled = true

        let hideSpinnerAnimationDuration: TimeInterval = 1
        DispatchQueue.main.asyncAfter(deadline: .now() + hideSpinnerAnimationDuration) { [weak self] in
            guard let self = self else { return }

            if case MessageValidationError.noPubRecipients = error, self.isMessagePasswordSupported {
                self.setMessagePassword()
            } else {
                self.showAlert(message: "compose_error".localized + "\n\n" + error.errorMessage)
            }
        }
    }

    private func handleSuccessfullySentMessage() {
        UIApplication.shared.isIdleTimerDisabled = false
        hideSpinner()
        navigationItem.rightBarButtonItem?.isEnabled = true
        showToast(input.successfullySentToast)
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - ASTableDelegate, ASTableDataSource

extension ComposeViewController: ASTableDelegate, ASTableDataSource {
    func numberOfSections(in _: ASTableNode) -> Int {
        Section.allCases.count
    }

    func tableNode(_: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        switch (state, section) {
        case (_, Section.recipient.rawValue):
            return RecipientPart.allCases.count
        case (.main, Section.password.rawValue):
            return isMessagePasswordSupported && contextToSend.hasRecipientsWithoutPubKey ? 1 : 0
        case (.main, Section.compose.rawValue):
            return ComposePart.allCases.count
        case (.main, Section.attachments.rawValue):
            return contextToSend.attachments.count
        case let (.searchEmails(emails), 1):
            return emails.isNotEmpty ? emails.count + 1 : 2
        case (.searchEmails, 2):
            return cloudContactProvider.isContactsScopeEnabled ? 0 : 2
        default:
            return 0
        }
    }

    // swiftlint:disable cyclomatic_complexity
    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self = self else { return ASCellNode() }

            switch (self.state, indexPath.section) {
            case (_, Section.recipient.rawValue):
                guard let part = RecipientPart(rawValue: indexPath.row) else { return ASCellNode() }
                switch part {
                case .input: return self.recipientInput()
                case .list: return self.recipientsNode()
                }
            case (.main, Section.password.rawValue):
                return self.messagePasswordNode()
            case (.main, Section.compose.rawValue):
                guard let part = ComposePart(rawValue: indexPath.row) else { return ASCellNode() }
                switch part {
                case .subject: return self.subjectNode()
                case .text: return self.textNode()
                case .topDivider, .subjectDivider: return DividerCellNode()
                }
            case (.main, Section.attachments.rawValue):
                guard !self.contextToSend.attachments.isEmpty else {
                    return ASCellNode()
                }
                return self.attachmentNode(for: indexPath.row)
            case let (.searchEmails(emails), 1):
                guard indexPath.row > 0 else { return DividerCellNode() }
                guard emails.isNotEmpty else { return self.noSearchResultsNode() }
                return InfoCellNode(input: self.decorator.styledRecipientInfo(with: emails[indexPath.row-1]))
            case (.searchEmails, 2):
                return indexPath.row == 0 ? DividerCellNode() : self.enableGoogleContactsNode()
            default:
                return ASCellNode()
            }
        }
    }

    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        if case let .searchEmails(emails) = state {
            switch indexPath.section {
            case 1:
                let selectedEmail = emails[safe: indexPath.row-1]
                handleEndEditingAction(with: selectedEmail)
            case 2:
                askForContactsPermission()
            default:
                break
            }
        } else if tableNode.nodeForRow(at: indexPath) is AttachmentNode {
            let controller = AttachmentViewController(
                file: contextToSend.attachments[indexPath.row],
                shouldShowDownloadButton: false
            )
            navigationController?.pushViewController(controller, animated: true )
        }
    }
}

// MARK: - Nodes

extension ComposeViewController {
    private func subjectNode() -> ASCellNode {
        TextFieldCellNode(
            input: decorator.styledTextFieldInput(
                with: "compose_subject".localized,
                accessibilityIdentifier: "subjectTextField"
            )
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
            if !self.input.isQuote, let node = self.node.visibleNodes.compactMap({ $0 as? TextViewCellNode }).first {
                node.becomeFirstResponder()
            } else {
                self.node.view.endEditing(true)
            }
            return true
        }
        .then {
            $0.attributedText = decorator.styledTitle(with: contextToSend.subject)
        }
    }

    private func messagePasswordNode() -> ASCellNode {
        let input = contextToSend.hasMessagePassword
        ? decorator.styledFilledMessagePasswordInput()
        : decorator.styledEmptyMessagePasswordInput()

        return MessagePasswordCellNode(
            input: input,
            setMessagePassword: { [weak self] in self?.setMessagePassword() }
        )
    }

    private func textNode() -> ASCellNode {
        let styledQuote = decorator.styledQuote(with: input)
        let height = max(decorator.frame(for: styledQuote).height, 40)
        return TextViewCellNode(
            decorator.styledTextViewInput(
                with: height,
                accessibilityIdentifier: "messageTextView"
            )
        ) { [weak self] event in
            guard let self = self else { return }
            switch event {
            case .didBeginEditing:
                break
            case .editingChanged(let text), .didEndEditing(let text):
                self.contextToSend.message = text?.string
            case .heightChanged(let textView):
                self.ensureCursorVisible(textView: textView)
            }
        }
        .then {
            let messageText = decorator.styledMessage(with: contextToSend.message ?? "")

            if input.isQuote && !messageText.string.contains(styledQuote.string) {
                let mutableString = NSMutableAttributedString(attributedString: messageText)
                mutableString.append(styledQuote)
                $0.textView.attributedText = mutableString
                $0.becomeFirstResponder()
            } else {
                $0.textView.attributedText = messageText
            }
        }
    }

    private func ensureCursorVisible(textView: UITextView) {
        guard let range = textView.selectedTextRange else { return }

        let cursorRect = textView.caretRect(for: range.start)

        var rectToMakeVisible = textView.convert(cursorRect, to: node.view)
        rectToMakeVisible.origin.y -= cursorRect.height
        rectToMakeVisible.size.height *= 3

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { // fix for animation lag
            self.node.view.scrollRectToVisible(rectToMakeVisible, animated: true)
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
            input: decorator.styledTextFieldInput(
                with: "compose_recipient".localized,
                keyboardType: .emailAddress,
                accessibilityIdentifier: "recipientTextField")
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
            if !self.input.isQuote {
                $0.becomeFirstResponder()
            }
        }
    }

    private func attachmentNode(for index: Int) -> ASCellNode {
        AttachmentNode(
            input: .init(
                attachment: contextToSend.attachments[index],
                index: index
            ),
            onDeleteTap: { [weak self] in
                self?.contextToSend.attachments.safeRemove(at: index)
                self?.node.reloadSections([Section.attachments.rawValue], with: .automatic)
            }
        )
    }

    private func noSearchResultsNode() -> ASCellNode {
        TextCellNode(input: .init(
            backgroundColor: .clear,
            title: "compose_no_contacts_found".localized,
            withSpinner: false,
            size: .zero,
            insets: UIEdgeInsets(top: 16, left: 8, bottom: 16, right: 8),
            itemsAlignment: .start)
        )
    }

    private func enableGoogleContactsNode() -> ASCellNode {
        TextWithIconNode(input: .init(
            title: "compose_enable_google_contacts_search".localized.attributed(.regular(16)),
            image: UIImage(named: "gmail_icn"))
        )
    }
}

// MARK: - Recipients Input
extension ComposeViewController {
    private var textField: TextFieldNode? {
        let indexPath = IndexPath(
            row: RecipientPart.input.rawValue,
            section: Section.recipient.rawValue
        )
        return (node.nodeForRow(at: indexPath) as? TextFieldCellNode)?.textField
    }

    private var recipientsIndexPath: IndexPath {
        IndexPath(row: RecipientPart.list.rawValue, section: Section.recipient.rawValue)
    }

    private var recipients: [ComposeMessageRecipient] {
        contextToSend.recipients
    }

    private func shouldChange(with textField: UITextField, and character: String) -> Bool {
        func nextResponder() {
            guard let node = node.visibleNodes[safe: ComposePart.subject.rawValue] as? TextFieldCellNode else { return }
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
        guard shouldEvaluateRecipientInput,
              let text = text, text.isNotEmpty
        else { return }

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
        search.send("")

        updateState(with: .main)
    }

    private func handleBackspaceAction(with textField: UITextField) {
        guard textField.text == "" else { return }

        let selectedRecipients = recipients
            .filter { $0.state.isSelected }

        guard selectedRecipients.isEmpty else {
            // remove selected recipients
            contextToSend.recipients = recipients.filter { !$0.state.isSelected }
            node.reloadSections([Section.recipient.rawValue, Section.password.rawValue],
                                with: .automatic)
            return
        }

        if let lastRecipient = contextToSend.recipients.popLast() {
            // select last recipient in a list
            var last = lastRecipient
            last.state = self.decorator.recipientSelectedState
            contextToSend.recipients.append(last)
            node.reloadRows(at: [recipientsIndexPath], with: .fade)
            node.reloadSections([Section.password.rawValue], with: .automatic)
        } else {
            // dismiss keyboard if no recipients left
            textField.resignFirstResponder()
        }
    }

    private func handleEditingChanged(with text: String?) {
        search.send(text ?? "")
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
            updateState(with: .searchEmails(Array(emails)))
        }
    }

    private func evaluate(recipient: ComposeMessageRecipient) {
        guard recipient.email.isValidEmail else {
            handleEvaluation(for: recipient, with: self.decorator.recipientInvalidEmailState, keyState: nil)
            return
        }

        Task {
            do {
                let contact = try await service.searchContact(with: recipient.email)
                let state = getRecipientState(from: contact)
                handleEvaluation(for: recipient, with: state, keyState: contact.keyState)
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

    private func handleEvaluation(for recipient: ComposeMessageRecipient,
                                  with state: RecipientState,
                                  keyState: PubKeyState?) {
        updateRecipientWithNew(
            state: state,
            keyState: keyState,
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
            keyState: nil,
            for: .left(recipient)
        )
    }

    private func updateRecipientWithNew(state: RecipientState,
                                        keyState: PubKeyState?,
                                        for context: Either<ComposeMessageRecipient, IndexPath>) {
        let index: Int? = {
            switch context {
            case let .left(recipient):
                return recipients.firstIndex(where: { $0.email == recipient.email })
            case let .right(index):
                return index.row
            }
        }()

        guard let recipientIndex = index else { return }
        contextToSend.recipients[recipientIndex].state = state
        contextToSend.recipients[recipientIndex].keyState = keyState

        node.reloadSections([Section.password.rawValue], with: .automatic)
        node.reloadRows(at: [recipientsIndexPath], with: .automatic)
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

        node.reloadRows(at: [recipientsIndexPath], with: .automatic)

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
                updateRecipientWithNew(state: decorator.recipientIdleState,
                                       keyState: nil,
                                       for: .right(indexPath))
                evaluate(recipient: recipient)
            } else {
                contextToSend.recipients.remove(at: indexPath.row)
                node.reloadRows(at: [recipientsIndexPath], with: .fade)
            }
        }
    }

    private func setMessagePassword() {
        Task {
            contextToSend.messagePassword = await enterMessagePassword()
            node.reloadSections([Section.password.rawValue], with: .automatic)
        }
    }

    private func enterMessagePassword() async -> String? {
        return await withCheckedContinuation { (continuation: CheckedContinuation<String?, Never>) in
            self.messagePasswordAlertController = createMessagePasswordAlert(continuation: continuation)
            self.present(self.messagePasswordAlertController!, animated: true, completion: nil)
        }
    }

    private func createMessagePasswordAlert(continuation: CheckedContinuation<String?, Never>) -> UIAlertController {
        let alert = UIAlertController(
            title: "compose_password_modal_title".localized,
            message: "compose_password_modal_message".localized,
            preferredStyle: .alert
        )

        alert.addTextField { [weak self] in
            guard let self = self else { return }
            $0.isSecureTextEntry = true
            $0.text = self.contextToSend.messagePassword
            $0.accessibilityLabel = "aid-message-password-textfield"
            $0.addTarget(self, action: #selector(self.messagePasswordTextFieldDidChange), for: .editingChanged)
        }

        let cancelAction = UIAlertAction(title: "cancel".localized, style: .cancel) { _ in
            return continuation.resume(returning: self.contextToSend.messagePassword)
        }
        alert.addAction(cancelAction)

        let setAction = UIAlertAction(title: "set".localized, style: .default) { _ in
            return continuation.resume(returning: alert.textFields?[0].text)
        }
        setAction.isEnabled = contextToSend.hasMessagePassword
        alert.addAction(setAction)

        return alert
    }

    @objc private func messagePasswordTextFieldDidChange(_ sender: UITextField) {
        messagePasswordAlertController?.actions[1].isEnabled = (sender.text ?? "").isNotEmpty
    }
}

// MARK: - State Handling
extension ComposeViewController {
    private func updateState(with newState: State) {
        state = newState

        switch state {
        case .main:
            node.reloadData()
        case .searchEmails:
            let sections: [Section] = [.password, .compose, .attachments]
            node.reloadSections(IndexSet(sections.map(\.rawValue)), with: .automatic)
        }
    }
}

// MARK: - UIDocumentPickerDelegate
extension ComposeViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let fileUrl = urls.first,
              let attachment = MessageAttachment(fileURL: fileUrl)
        else {
            showAlert(message: "files_picking_files_error_message".localized)
            return
        }
        appendAttachmentIfAllowed(attachment)
        node.reloadSections([Section.attachments.rawValue], with: .automatic)
    }
}

// MARK: - PHPickerViewControllerDelegate
extension ComposeViewController: PHPickerViewControllerDelegate {
    nonisolated func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        Task {
            await picker.dismiss(animated: true)
            await handleResults(results)
        }
    }

    private func handleResults(_ results: [PHPickerResult]) {
        let itemProvider = results.first?.itemProvider
        if itemProvider?.hasItemConformingToTypeIdentifier("public.movie") == true {
            itemProvider?.loadFileRepresentation(
                forTypeIdentifier: "public.movie",
                completionHandler: { [weak self] url, error in
                    DispatchQueue.main.async {
                        self?.handleRepresentation(
                            url: url,
                            error: error,
                            isVideo: true
                        )
                    }
                }
            )
        } else {
            itemProvider?.loadFileRepresentation(
                forTypeIdentifier: "public.image",
                completionHandler: { [weak self] url, error in
                    DispatchQueue.main.async {
                        self?.handleRepresentation(
                            url: url,
                            error: error,
                            isVideo: false
                        )
                    }
                }
            )
        }
    }

    private func handleRepresentation(url: URL?, error: Error?, isVideo: Bool) {
        guard
            let url = url,
            let composeMessageAttachment = MessageAttachment(fileURL: url)
        else {
            let message = isVideo ? "files_picking_videos_error_message".localized
                : "files_picking_photos_error_message".localized
            let errorMessage = error.flatMap({ "." + $0.localizedDescription }) ?? ""
            showAlert(message: message + errorMessage)
            return
        }

        appendAttachmentIfAllowed(composeMessageAttachment)
        node.reloadSections([Section.attachments.rawValue], with: .automatic)
    }
}

// MARK: - UIImagePickerControllerDelegate & UINavigationControllerDelegate
extension ComposeViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        picker.dismiss(animated: true, completion: nil)

        let composeMessageAttachment: MessageAttachment?
        switch picker.sourceType {
        case .camera:
            composeMessageAttachment = MessageAttachment(cameraSourceMediaInfo: info)
        default: fatalError("No other image picker's sources should be used")
        }
        guard let attachment = composeMessageAttachment else {
            showAlert(message: "files_picking_photos_error_message".localized)
            return
        }
        appendAttachmentIfAllowed(attachment)
        node.reloadSections([Section.attachments.rawValue], with: .automatic)
    }

    private func appendAttachmentIfAllowed(_ attachment: MessageAttachment) {
        let totalSize = contextToSend.attachments.map(\.size).reduce(0, +) + attachment.size
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
                handler: { [weak self] _ in self?.takePhoto() }
            )
        )
        alert.addAction(
            UIAlertAction(
                title: "files_picking_photo_library_source".localized,
                style: .default,
                handler: { [weak self] _ in self?.selectPhoto() }
            )
        )
        alert.addAction(
            UIAlertAction(
                title: "files_picking_files_source".localized,
                style: .default,
                handler: { [weak self] _ in self?.selectFromFilesApp() }
            )
        )
        alert.addAction(UIAlertAction(title: "cancel".localized, style: .cancel))
        present(alert, animated: true, completion: nil)
    }

    private func takePhoto() {
        Task {
            do {
                try await photosManager.takePhoto(from: self)
            } catch {
                showNoAccessToCameraAlert()
            }
        }
    }

    private func selectPhoto() {
        Task {
            await photosManager.selectPhoto(from: self)
        }
    }

    private func selectFromFilesApp() {
        Task {
            await filesManager.selectFromFilesApp(from: self)
        }
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

    private func showNoAccessToCameraAlert() {
        let alert = UIAlertController(
            title: "files_picking_no_camera_access_error_title".localized,
            message: "files_picking_no_camera_access_error_message".localized,
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

    private func askForContactsPermission() {
        shouldEvaluateRecipientInput = false

        Task {
            do {
                try await router.askForContactsPermission(for: .gmailLogin(self), appContext: appContext)
                node.reloadSections([2], with: .automatic)
            } catch {
                handleContactsPermissionError(error)
            }
        }
    }

    private func handleContactsPermissionError(_ error: Error) {
        guard let gmailUserError = error as? GoogleUserServiceError,
           case .userNotAllowedAllNeededScopes(let missingScopes) = gmailUserError
        else { return }

        let scopes = missingScopes.map(\.title).joined(separator: ", ")

        let alert = UIAlertController(
            title: "error".localized,
            message: "compose_missing_contacts_scopes".localizeWithArguments(scopes),
            preferredStyle: .alert
        )
        let laterAction = UIAlertAction(
            title: "later".localized,
            style: .cancel
        )
        let allowAction = UIAlertAction(
            title: "allow".localized,
            style: .default
        ) { [weak self] _ in
            self?.askForContactsPermission()
        }
        alert.addAction(laterAction)
        alert.addAction(allowAction)

        present(alert, animated: true, completion: nil)
    }
}

extension ComposeViewController: FilesManagerPresenter {}

// TODO temporary solution for background execution problem
private actor ServiceActor {
    let composeMessageService: ComposeMessageService
    private let contactsService: ContactsServiceType
    private let cloudContactProvider: CloudContactsProvider

    init(composeMessageService: ComposeMessageService,
         contactsService: ContactsServiceType,
         cloudContactProvider: CloudContactsProvider) {
        self.composeMessageService = composeMessageService
        self.contactsService = contactsService
        self.cloudContactProvider = cloudContactProvider
    }

    func encryptAndSend(message: SendableMsg, threadId: String?) async throws {
        try await composeMessageService.encryptAndSend(
            message: message,
            threadId: threadId
        )
    }

    func searchContacts(query: String) async throws -> [String] {
        return try await cloudContactProvider.searchContacts(query: query)
    }

    func searchContact(with email: String) async throws -> RecipientWithSortedPubKeys {
        return try await contactsService.searchContact(with: email)
    }
}
