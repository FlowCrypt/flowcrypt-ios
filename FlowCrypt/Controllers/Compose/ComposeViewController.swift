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
/**
 * View controller to compose the message and send it
 * - User can be redirected here from *InboxViewController* by tapping on *+*
 * - Or from *ThreadDetailsViewController* controller by tapping on *reply* or *forward*
 **/
final class ComposeViewController: TableNodeViewController {
    private var calculatedRecipientsToPartHeight: CGFloat? {
        didSet {
            let sections: [Section] = [.to, .password]
            node.reloadSections(IndexSet(sections.map(\.rawValue)), with: .automatic)
        }
    }
    private var calculatedRecipientsCcPartHeight: CGFloat? {
        didSet {
            let sections: [Section] = [.to, .cc, .password]
            node.reloadSections(IndexSet(sections.map(\.rawValue)), with: .automatic)
        }
    }
    private var calculatedRecipientsBccPartHeight: CGFloat? {
        didSet {
            let sections: [Section] = [.to, .bcc, .password]
            node.reloadSections(IndexSet(sections.map(\.rawValue)), with: .automatic)
        }
    }

    private enum Constants {
        static let endTypingCharacters = [",", " ", "\n", ";"]
        static let minRecipientsPartHeight: CGFloat = 44
    }

    private struct ComposedDraft: Equatable {
        let email: String
        let input: ComposeMessageInput
        let contextToSend: ComposeMessageContext
    }

    private enum State {
        case main, searchEmails([String])
    }

    private enum Section: Int, CaseIterable {
        case to, cc, bcc, password, compose, attachments

        var recipientType: RecipientType? {
            switch self {
            case .to:
                return .to
            case .cc:
                return .cc
            case .bcc:
                return .bcc
            case .password, .compose, .attachments:
                return nil
            }
        }

        static func recipientsSection(type: RecipientType) -> Section {
            switch type {
            case .to:
                return .to
            case .cc:
                return .cc
            case .bcc:
                return .bcc
            }
        }
    }

    private enum RecipientPart: Int, CaseIterable {
        case list, input
    }

    private enum ComposePart: Int, CaseIterable {
        case topDivider, subject, subjectDivider, text
    }

    private let appContext: AppContextWithUser
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
        clientConfiguration.isUsingFes
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

    private var selectedRecipientType: RecipientType?
    private var shouldShowAllRecipientTypes = false

    init(
        appContext: AppContextWithUser,
        notificationCenter: NotificationCenter = .default,
        decorator: ComposeViewDecorator = ComposeViewDecorator(),
        input: ComposeMessageInput = .empty,
        cloudContactProvider: CloudContactsProvider? = nil,
        contactsService: ContactsServiceType? = nil,
        composeMessageService: ComposeMessageService? = nil,
        filesManager: FilesManagerType = FilesManager(),
        photosManager: PhotosManagerType = PhotosManager(),
        keyMethods: KeyMethodsType = KeyMethods()
    ) throws {
        self.appContext = appContext
        self.email = appContext.user.email
        self.notificationCenter = notificationCenter
        self.input = input
        self.decorator = decorator
        let clientConfiguration = try appContext.clientConfigurationService.getSaved(for: appContext.user.email)
        self.contactsService = contactsService ?? ContactsService(
            localContactsProvider: LocalContactsProvider(
                encryptedStorage: appContext.encryptedStorage
            ),
            clientConfiguration: clientConfiguration
        )
        let cloudContactProvider = cloudContactProvider ?? UserContactsProvider(
            userService: GoogleUserService(
                currentUserEmail: appContext.user.email,
                appDelegateGoogleSessionContainer: UIApplication.shared.delegate as? AppDelegate
            )
        )
        self.cloudContactProvider = cloudContactProvider
        self.composeMessageService = composeMessageService ?? ComposeMessageService(
            clientConfiguration: clientConfiguration,
            encryptedStorage: appContext.encryptedStorage,
            messageGateway: appContext.getRequiredMailProvider().messageSender,
            passPhraseService: appContext.passPhraseService,
            sender: appContext.user.email
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

        evaluateAllRecipients()
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

    private func evaluateAllRecipients() {
        contextToSend.recipients.forEach {
            evaluate(recipient: $0)
        }
    }

    func update(with message: Message) {
        self.contextToSend.subject = message.subject
        self.contextToSend.message = message.raw
        self.contextToSend.recipients = [
            ComposeMessageRecipient(
                email: "tom@flowcrypt.com",
                type: .to,
                state: decorator.recipientIdleState
            )
        ]
    }

    private func observeComposeUpdates() {
        composeMessageService.onStateChanged { [weak self] state in
            self?.updateSpinner(with: state)
        }
    }

    @MainActor
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
            let recipient = ComposeMessageRecipient(email: email, type: .to, state: decorator.recipientIdleState)
            contextToSend.add(recipient: recipient)
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
            signingPrv: signingKey
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

            if self.isMessagePasswordSupported {
                switch error {
                case MessageValidationError.noPubRecipients:
                    self.setMessagePassword()
                case MessageValidationError.notUniquePassword,
                    MessageValidationError.subjectContainsPassword,
                    MessageValidationError.weakPassword:
                    self.showAlert(message: error.errorMessage)
                default:
                    self.showAlert(message: "compose_error".localized + "\n\n" + error.errorMessage)
                }
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
        case (.main, Section.to.rawValue):
            return RecipientPart.allCases.count
        case (.main, Section.cc.rawValue), (.main, Section.bcc.rawValue):
            return shouldShowAllRecipientTypes ? RecipientPart.allCases.count : 0
        case (.main, Section.password.rawValue):
            return isMessagePasswordSupported && contextToSend.hasRecipientsWithoutPubKey ? 1 : 0
        case (.main, Section.compose.rawValue):
            return ComposePart.allCases.count
        case (.main, Section.attachments.rawValue):
            return contextToSend.attachments.count
        case (.searchEmails, Section.to.rawValue),
             (.searchEmails, Section.cc.rawValue),
             (.searchEmails, Section.bcc.rawValue):
            let recipientType = Section(rawValue: section)?.recipientType
            return selectedRecipientType == recipientType ? RecipientPart.allCases.count : 0
        case let (.searchEmails(emails), RecipientType.allCases.count):
            return emails.isNotEmpty ? emails.count + 1 : 2
        case (.searchEmails, RecipientType.allCases.count + 1):
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
            case (_, Section.to.rawValue), (_, Section.cc.rawValue), (_, Section.bcc.rawValue):
                let recipientType = RecipientType.allCases[indexPath.section]
                if indexPath.row == 0 {
                    return self.recipientsNode(type: recipientType)
                } else {
                    return self.recipientInput(type: recipientType)
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
            case let (.searchEmails(emails), RecipientType.allCases.count):
                guard indexPath.row > 0 else { return DividerCellNode() }
                guard emails.isNotEmpty else { return self.noSearchResultsNode() }
                return InfoCellNode(input: self.decorator.styledRecipientInfo(with: emails[indexPath.row-1]))
            case (.searchEmails, RecipientType.allCases.count + 1):
                return indexPath.row == 0 ? DividerCellNode() : self.enableGoogleContactsNode()
            default:
                return ASCellNode()
            }
        }
    }

    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        if case let .searchEmails(emails) = state, let recipientType = selectedRecipientType {
            switch indexPath.section {
            case RecipientType.allCases.count:
                let selectedEmail = emails[safe: indexPath.row-1]
                handleEndEditingAction(with: selectedEmail, for: recipientType)
            case RecipientType.allCases.count + 1:
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
                if input.isReply {
                    $0.becomeFirstResponder()
                }
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

    private func recipientsNode(type: RecipientType) -> ASCellNode {
        let recipients = contextToSend.recipients(of: type)
        let shouldShowToggleButton = type == .to
            && recipients.isNotEmpty
            && !contextToSend.hasCcOrBccRecipients

        return RecipientEmailsCellNode(
            recipients: recipients.map(RecipientEmailsCellNode.RecipientInput.init),
            height: recipientsNodeHeight(type: type) ?? Constants.minRecipientsPartHeight,
            isToggleButtonRotated: shouldShowAllRecipientTypes,
            toggleButtonAction: shouldShowToggleButton ? { [weak self] in
                guard type == .to else { return }
                self?.toggleRecipientsList()
            } : nil
        )
            .onLayoutHeightChanged { [weak self] layoutHeight in
                self?.updateRecipientsNode(
                    layoutHeight: layoutHeight,
                    type: type
                )
            }
            .onItemSelect { [weak self] (action: RecipientEmailsCellNode.RecipientEmailTapAction) in
                switch action {
                case let .imageTap(indexPath):
                    self?.handleRecipientAction(with: indexPath, type: type)
                case let .select(indexPath):
                    self?.handleRecipientSelection(with: indexPath, type: type)
                }
            }
    }

    private func recipientsNodeHeight(type: RecipientType) -> CGFloat? {
        switch type {
        case .to:
            return calculatedRecipientsToPartHeight
        case .cc:
            return calculatedRecipientsCcPartHeight
        case .bcc:
            return calculatedRecipientsBccPartHeight
        }
    }

    private func updateRecipientsNode(layoutHeight: CGFloat, type: RecipientType) {
        let currentHeight = self.recipientsNodeHeight(type: type)

        guard currentHeight != layoutHeight, layoutHeight > 0 else {
            return
        }

        switch type {
        case .to:
            self.calculatedRecipientsToPartHeight = layoutHeight
        case .cc:
            self.calculatedRecipientsCcPartHeight = layoutHeight
        case .bcc:
            self.calculatedRecipientsBccPartHeight = layoutHeight
        }
    }

    private func recipientInput(type: RecipientType) -> ASCellNode {
        let shouldShowToggleButton = type == .to
            && contextToSend.recipients(of: .to).isEmpty
            && !contextToSend.hasCcOrBccRecipients

        return RecipientEmailTextFieldNode(
            input: decorator.styledTextFieldInput(
                with: type.inputPlaceholder,
                keyboardType: .emailAddress,
                accessibilityIdentifier: "aid-recipient-text-field-\(type.rawValue)"
            ),
            action: { [weak self] action in
                self?.handle(textFieldAction: action, for: type)
            },
            isToggleButtonRotated: shouldShowAllRecipientTypes,
            toggleButtonAction: shouldShowToggleButton ? { [weak self] in
                guard type == .to else { return }
                self?.toggleRecipientsList()
            } : nil
        )
        .onShouldReturn {
            $0.resignFirstResponder()
            return true
        }
        .onShouldChangeCharacters { [weak self] textField, character -> (Bool) in
            self?.shouldChange(with: textField, and: character, for: type) ?? true
        }
        .then {
            $0.isLowercased = true

            guard type == .to,
                  self.input.isForward || self.input.isIdle
            else { return }

            $0.becomeFirstResponder()
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
            insets: .deviceSpecificTextInsets(top: 16, bottom: 16),
            itemsAlignment: .start)
        )
    }

    private func enableGoogleContactsNode() -> ASCellNode {
        TextWithIconNode(input: .init(
            title: "compose_enable_google_contacts_search"
                .localized
                .attributed(.regular(16)),
            image: UIImage(named: "gmail_icn"))
        )
    }
}

// MARK: - Recipients Input
extension ComposeViewController {
    private func shouldChange(with textField: UITextField, and character: String, for recipientType: RecipientType) -> Bool {
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
                handleEndEditingAction(with: $0, for: recipientType)
            }
            return false
        } else if Constants.endTypingCharacters.contains(character) {
            handleEndEditingAction(with: textField.text, for: recipientType)
            nextResponder()
            return false
        } else {
            return true
        }
    }

    private func handle(textFieldAction: TextFieldActionType, for recipientType: RecipientType) {
        switch textFieldAction {
        case let .deleteBackward(textField): handleBackspaceAction(with: textField, for: recipientType)
        case let .didEndEditing(text): handleEndEditingAction(with: text, for: recipientType)
        case let .editingChanged(text): handleEditingChanged(with: text, for: recipientType)
        case .didBeginEditing: handleDidBeginEditing()
        }
    }

    private func handleEndEditingAction(with text: String?, for recipientType: RecipientType) {
        guard shouldEvaluateRecipientInput,
              let text = text, text.isNotEmpty
        else { return }

        let recipients = contextToSend.recipients(of: recipientType)
        let indexPath = recipientsIndexPath(type: recipientType, part: .list)

        let textField = recipientsTextField(type: recipientType)
        textField?.reset()

        // Set all selected recipients to idle state
        let idleRecipients: [ComposeMessageRecipient] = recipients.map { recipient in
            var recipient = recipient
            if recipient.state.isSelected {
                recipient.state = self.decorator.recipientIdleState
            }
            return recipient
        }

        contextToSend.set(recipients: idleRecipients, for: recipientType)

        let newRecipient = ComposeMessageRecipient(email: text, type: recipientType, state: decorator.recipientIdleState)
        let indexOfRecipient: Int

        if let index = idleRecipients.firstIndex(where: { $0.email == newRecipient.email }) {
            // recipient already in list
            evaluate(recipient: newRecipient)
            indexOfRecipient = index
        } else {
            // add new recipient
            contextToSend.add(recipient: newRecipient)
            node.reloadRows(at: [indexPath], with: .automatic)
            evaluate(recipient: newRecipient)

            // scroll to the latest recipient
            indexOfRecipient = recipients.endIndex - 1
        }

        let collectionNode = (node.nodeForRow(at: indexPath) as? RecipientEmailsCellNode)?.collectionNode
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            collectionNode?.scrollToItem(
                at: IndexPath(row: indexOfRecipient, section: 0),
                at: .bottom,
                animated: true
            )
        }

        node.view.keyboardDismissMode = .interactive
        search.send("")

        updateState(with: .main)
    }

    private func recipientsIndexPath(type: RecipientType, part: RecipientPart) -> IndexPath {
        let section = Section.recipientsSection(type: type)
        return IndexPath(row: part.rawValue, section: section.rawValue)
    }

    private func recipientsTextField(type: RecipientType) -> TextFieldNode? {
        let indexPath = recipientsIndexPath(type: type, part: .input)
        return (node.nodeForRow(at: indexPath) as? RecipientEmailTextFieldNode)?.textField
    }

    private func handleBackspaceAction(with textField: UITextField, for recipientType: RecipientType) {
        guard textField.text == "" else { return }

        var recipients = contextToSend.recipients(of: recipientType)

        let indexPath = recipientsIndexPath(type: recipientType, part: .input)
        let selectedRecipients = recipients.filter { $0.state.isSelected }
        let recipientsSection = Section.recipientsSection(type: recipientType)

        guard selectedRecipients.isEmpty else {
            let sectionsToReload: [Section] = [.to, recipientsSection, .password]
            let notSelectedRecipients = recipients.filter { !$0.state.isSelected }
            contextToSend.set(recipients: notSelectedRecipients, for: recipientType)

            node.reloadSections(
                IndexSet(sectionsToReload.map(\.rawValue).unique()),
                with: .automatic
            )

            return
        }

        if var lastRecipient = recipients.last {
            // select last recipient in a list
            lastRecipient.state = self.decorator.recipientSelectedState
            recipients.append(lastRecipient)
            contextToSend.set(recipients: recipients, for: recipientType)
            node.reloadRows(at: [indexPath], with: .fade)

            let sectionsToReload: [Section] = [.to, .password]
            node.reloadSections(IndexSet(sectionsToReload.map(\.rawValue)), with: .automatic)
        } else {
            // dismiss keyboard if no recipients left
            textField.resignFirstResponder()
        }
    }

    private func handleEditingChanged(with text: String?, for recipientType: RecipientType) {
        selectedRecipientType = recipientType
        search.send(text ?? "")
    }

    private func handleDidBeginEditing() {
        node.view.keyboardDismissMode = .none
    }

    private func toggleRecipientsList() {
        let sections: [Section] = [.cc, .bcc]
        shouldShowAllRecipientTypes.toggle()

        node.reloadSections(IndexSet(sections.map(\.rawValue)), with: .automatic)
    }
}

// MARK: - Action Handling
extension ComposeViewController {
    private func searchEmail(with query: String) {
        Task {
            do {
                let localEmails = try contactsService.searchLocalContacts(query: query)
                let cloudEmails = try? await service.searchContacts(query: query)
                let emails = Set([localEmails, cloudEmails].compactMap { $0 }.flatMap { $0 })
                updateState(with: .searchEmails(Array(emails)))
            } catch {
                showAlert(message: error.localizedDescription)
            }
        }
    }

    private func evaluate(recipient: ComposeMessageRecipient) {
        guard recipient.email.isValidEmail else {
            updateRecipient(
                email: recipient.email,
                state: decorator.recipientInvalidEmailState
            )
            return
        }

        Task {
            do {
                if let contact = try await service.findLocalContact(with: recipient.email) {
                    handleEvaluation(for: contact)
                }

                let contactWithFetchedKeys = try await service.fetchContact(with: recipient.email)
                handleEvaluation(for: contactWithFetchedKeys)
            } catch {
                handleEvaluation(error: error, with: recipient.email)
            }
        }
    }

    private func handleEvaluation(for recipient: RecipientWithSortedPubKeys) {
        let state = getRecipientState(from: recipient)

        updateRecipient(
            email: recipient.email,
            state: state,
            keyState: recipient.keyState
        )
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

    private func handleEvaluation(error: Error, with email: String) {
        let recipientState: RecipientState = {
            switch error {
            case ContactsError.keyMissing:
                return self.decorator.recipientKeyNotFoundState
            default:
                return self.decorator.recipientErrorStateRetry
            }
        }()

        updateRecipient(
            email: email,
            state: recipientState,
            keyState: nil
        )
    }

    private func updateRecipient(
        email: String,
        state: RecipientState,
        keyState: PubKeyState? = nil
    ) {
        contextToSend.recipients.indices.forEach { index in
            guard contextToSend.recipients[index].email == email else { return }

            let recipient = contextToSend.recipients[index]
            let needsReload = recipient.state != state || recipient.keyState != keyState

            contextToSend.recipients[index].state = state
            contextToSend.recipients[index].keyState = keyState

            if needsReload, selectedRecipientType == nil || selectedRecipientType == recipient.type {
                let section = Section.recipientsSection(type: recipient.type)
                node.reloadSections(IndexSet([section.rawValue]), with: .automatic)
            }
        }

        node.reloadSections([Section.password.rawValue], with: .automatic)
    }

    private func handleRecipientSelection(with indexPath: IndexPath, type: RecipientType) {
        guard let recipient = contextToSend.recipient(at: indexPath.row, type: type) else { return }

        let listIndexPath = recipientsIndexPath(type: type, part: .list)
        let isSelected = recipient.state.isSelected
        let state = isSelected ? decorator.recipientIdleState : decorator.recipientSelectedState
        contextToSend.update(recipient: recipient.email, type: type, state: state)

        if isSelected {
            evaluate(recipient: recipient)
        }

        node.reloadRows(at: [listIndexPath], with: .automatic)

        let textField = recipientsTextField(type: type)
        if !(textField?.isFirstResponder() ?? true) {
            textField?.becomeFirstResponder()
        }
        textField?.reset()
    }

    private func handleRecipientAction(with indexPath: IndexPath, type: RecipientType) {
        guard let recipient = contextToSend.recipient(at: indexPath.row, type: type) else { return }

        switch recipient.state {
        case .idle:
            handleRecipientSelection(with: indexPath, type: type)
        case .keyFound, .keyExpired, .keyRevoked, .keyNotFound, .invalidEmail, .selected:
            break
        case let .error(_, isRetryError):
            if isRetryError {
                updateRecipient(
                    email: recipient.email,
                    state: decorator.recipientIdleState,
                    keyState: nil
                )
                evaluate(recipient: recipient)
            } else {
                let listIndexPath = recipientsIndexPath(type: type, part: .list)
                contextToSend.remove(recipient: recipient.email, type: type)
                node.reloadRows(at: [listIndexPath], with: .automatic)
            }
        }
    }

    // MARK: - Message password
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
        let password = sender.text ?? ""
        let isPasswordStrong = composeMessageService.isMessagePasswordStrong(pwd: password)
        messagePasswordAlertController?.actions[1].isEnabled = isPasswordStrong
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
            let sections: [Section]
            if let type = selectedRecipientType {
                let selectedRecipientSection = Section.recipientsSection(type: type)
                sections = Section.allCases.filter { $0 != selectedRecipientSection }
            } else {
                sections = Section.allCases
            }
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
        guard let itemProvider = results.first?.itemProvider else { return }

        enum MediaType: String {
            case image, movie

            var identifier: String { "public.\(rawValue)" }
        }

        let isVideo = itemProvider.hasItemConformingToTypeIdentifier(MediaType.movie.identifier)
        let mediaType: MediaType = isVideo ? .movie : .image

        itemProvider.loadFileRepresentation(
            forTypeIdentifier: mediaType.identifier,
            completionHandler: { [weak self] url, error in
                DispatchQueue.main.async {
                    self?.handleRepresentation(
                        url: url,
                        error: error,
                        isVideo: isVideo
                    )
                }
            }
        )
    }

    private func handleRepresentation(url: URL?, error: Error?, isVideo: Bool) {
        guard
            let url = url,
            let composeMessageAttachment = MessageAttachment(fileURL: url)
        else {
            let message = isVideo
                ? "files_picking_videos_error_message".localized
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
            message: nil,
            preferredStyle: .actionSheet
        ).popoverPresentation(style: .centred(view))

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
            title: "ok".localized,
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
            title: "ok".localized,
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

    func findLocalContact(with email: String) async throws -> RecipientWithSortedPubKeys? {
        return try await contactsService.findLocalContact(with: email)
    }

    func fetchContact(with email: String) async throws -> RecipientWithSortedPubKeys {
        return try await contactsService.fetchContact(with: email)
    }
}
