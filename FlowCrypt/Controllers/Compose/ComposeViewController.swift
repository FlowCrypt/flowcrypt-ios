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

    private enum Constants {
        static let endTypingCharacters = [",", "\n", ";"]
        static let minRecipientsPartHeight: CGFloat = 32
    }

    private struct ComposedDraft: Equatable {
        let email: String
        let input: ComposeMessageInput
        let contextToSend: ComposeMessageContext
    }

    private enum State {
        case main, searchEmails([Recipient])
    }

    enum Section: Hashable {
        case recipientsLabel, recipients(RecipientType), password, compose, attachments, searchResults, contacts

        static var recipientsSections: [Section] {
            RecipientType.allCases.map { Section.recipients($0) }
        }
    }

    private enum RecipientPart: Int, CaseIterable {
        case list, input
    }

    private enum ComposePart: Int, CaseIterable {
        case topDivider, subject, subjectDivider, text
    }

    private var userFinishedSearching = false
    private var isRecipientLoading = false
    private var userTappedOutSideRecipientsArea = false
    private var shouldShowEmailRecipientsLabel = false
    private let appContext: AppContextWithUser
    private let composeMessageService: ComposeMessageService
    private let notificationCenter: NotificationCenter
    private var decorator: ComposeViewDecorator
    private let localContactsProvider: LocalContactsProviderType
    private let cloudContactProvider: CloudContactsProvider
    private let filesManager: FilesManagerType
    private let photosManager: PhotosManagerType
    private let keyMethods: KeyMethodsType
    private let service: ServiceActor
    private let router: GlobalRouterType
    private let clientConfiguration: ClientConfiguration

    private let email: String
    private var isMessagePasswordSupported: Bool {
        return clientConfiguration.isUsingFes
    }

    private let search = PassthroughSubject<String, Never>()
    private var cancellable = Set<AnyCancellable>()
    private var isPreviousSearchStateEmpty = false

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

    private var selectedRecipientType: RecipientType? = .to
    private var shouldShowAllRecipientTypes = false

    private var sectionsList: [Section] = []

    init(
        appContext: AppContextWithUser,
        notificationCenter: NotificationCenter = .default,
        decorator: ComposeViewDecorator = ComposeViewDecorator(),
        input: ComposeMessageInput = .empty,
        cloudContactProvider: CloudContactsProvider? = nil,
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
        self.localContactsProvider = LocalContactsProvider(
            encryptedStorage: appContext.encryptedStorage
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
            localContactsProvider: localContactsProvider,
            pubLookup: PubLookup(clientConfiguration: clientConfiguration, localContactsProvider: self.localContactsProvider),
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
        for recipient in contextToSend.recipients {
             evaluate(recipient: recipient, showRecipientLabelFlag: false)
         }
    }

    func update(with message: Message) {
        self.contextToSend.subject = message.subject
        self.contextToSend.message = message.raw
        message.to.forEach { recipient in
            evaluateMessage(recipient: recipient, type: .to)
        }
        message.cc.forEach { recipient in
            evaluateMessage(recipient: recipient, type: .cc)
        }
        message.bcc.forEach { recipient in
            evaluateMessage(recipient: recipient, type: .bcc)
        }
    }

    func evaluateMessage(recipient: Recipient, type: RecipientType) {
        let recipient = ComposeMessageRecipient(
            email: recipient.email,
            name: recipient.name,
            type: .to,
            state: decorator.recipientIdleState
        )
        contextToSend.add(recipient: recipient)
        evaluate(recipient: recipient)
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

        updateState(with: .main)
    }

    private func setupQuote() {
        guard input.isQuote else { return }

        input.quoteRecipients.forEach { recipient in
            evaluateMessage(recipient: recipient, type: .to)
        }

        input.quoteCCRecipients.forEach { recipient in
            evaluateMessage(recipient: recipient, type: .cc)
        }

        if input.quoteCCRecipients.isNotEmpty {
            shouldShowAllRecipientTypes.toggle()
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
                if query.isEmpty {
                    self?.isPreviousSearchStateEmpty = true
                    self?.updateState(with: .main)
                }
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
        sectionsList.count
    }

    func tableNode(_: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        guard let sectionItem = sectionsList[safe: section] else { return 0 }

        switch (state, sectionItem) {
        case (.main, .recipientsLabel):
            return shouldShowEmailRecipientsLabel ? RecipientPart.allCases.count : 0
        case (.main, .recipients(.to)):
            return shouldShowEmailRecipientsLabel ? 0 : RecipientPart.allCases.count
        case (.main, .recipients(.cc)), (.main, .recipients(.bcc)):
            return !shouldShowEmailRecipientsLabel && shouldShowAllRecipientTypes ? RecipientPart.allCases.count : 0
        case (.main, .password):
            return isMessagePasswordSupported && contextToSend.hasRecipientsWithoutPubKey ? 1 : 0
        case (.main, .compose):
            return ComposePart.allCases.count
        case (.main, .attachments):
            return contextToSend.attachments.count
        case (.searchEmails, .recipients(let type)):
            return selectedRecipientType == type ? RecipientPart.allCases.count : 0
        case let (.searchEmails(emails), .searchResults):
            return emails.isNotEmpty ? emails.count + 1 : 2
        case (.searchEmails, .contacts):
            return cloudContactProvider.isContactsScopeEnabled ? 0 : 2
        default:
            return 0
        }
    }

    // swiftlint:disable cyclomatic_complexity
    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self = self,
                  let section = self.sectionsList[safe: indexPath.section]
            else { return ASCellNode() }

            switch (self.state, section) {
            case (_, .recipients(.to)), (_, .recipients(.cc)), (_, .recipients(.bcc)):
                let recipientType = RecipientType.allCases[indexPath.section]
                if indexPath.row == 0 {
                    return self.recipientsNode(type: recipientType)
                } else {
                    return self.recipientInput(type: recipientType)
                }
            case (.main, .recipientsLabel):
                if indexPath.row > 0 {
                    return ASCellNode()
                }
                return self.recipientTextNode()
            case (.main, .password):
                return self.messagePasswordNode()
            case (.main, .compose):
                guard let part = ComposePart(rawValue: indexPath.row) else { return ASCellNode() }
                switch part {
                case .subject: return self.subjectNode()
                case .text: return self.textNode()
                case .topDivider, .subjectDivider: return DividerCellNode()
                }
            case (.main, .attachments):
                guard !self.contextToSend.attachments.isEmpty else {
                    return ASCellNode()
                }
                return self.attachmentNode(for: indexPath.row)
            case let (.searchEmails(recipients), .searchResults):
                guard indexPath.row > 0 else { return DividerCellNode() }
                guard recipients.isNotEmpty else { return self.noSearchResultsNode() }
                guard let recipient = recipients[safe: indexPath.row-1] else { return ASCellNode() }

                if let name = recipient.name {
                    let input = self.decorator.styledRecipientInfo(
                        with: recipient.email,
                        name: name
                    )
                    return LabelCellNode(input: input)
                } else {
                    let input = self.decorator.styledRecipientInfo(with: recipient.email)
                    return InfoCellNode(input: input)
                }
            case (.searchEmails, .contacts):
                return indexPath.row == 0 ? DividerCellNode() : self.enableGoogleContactsNode()
            default:
                return ASCellNode()
            }
        }
    }

    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        if case let .searchEmails(recipients) = state, let recipientType = selectedRecipientType {
            guard let section = sectionsList[safe: indexPath.section] else { return }

            switch section {
            case .searchResults:
                let recipient = recipients[safe: indexPath.row-1]
                handleEndEditingAction(with: recipient?.email, name: recipient?.name, for: recipientType)
            case .contacts:
                askForContactsPermission()
            default:
                break
            }
        } else if tableNode.nodeForRow(at: indexPath) is AttachmentNode {
            let controller = AttachmentViewController(
                file: contextToSend.attachments[indexPath.row],
                shouldShowDownloadButton: false
            )
            navigationController?.pushViewController(controller, animated: true)
        }
    }

    private func reload(sections: [Section]) {
        let indexes = sectionsList.enumerated().compactMap { index, section in
            sections.contains(section) ? index : nil
        }

        node.reloadSections(IndexSet(indexes), with: .automatic)
    }
}

// MARK: - Nodes
extension ComposeViewController {
    private func recipientTextNode() -> ComposeRecipientCellNode {
        let recipients = contextToSend.recipients.map(RecipientEmailsCellNode.Input.init)
        let textNode = ComposeRecipientCellNode(
            input: ComposeRecipientCellNode.Input(recipients: recipients),
            accessibilityIdentifier: "aid-recipient-list-text",
            titleNodeBackgroundColorSelected: .titleNodeBackgroundColorSelected,
            tapAction: { [weak self] in
                self?.hideRecipientLabel()
            }
        )
        return textNode
    }

    private func showRecipientLabelIfNecessary() {
        guard !self.isRecipientLoading,
              self.contextToSend.recipients.isNotEmpty,
              self.userTappedOutSideRecipientsArea else {
            return
        }
        if !self.shouldShowEmailRecipientsLabel {
            self.shouldShowEmailRecipientsLabel = true
            self.userTappedOutSideRecipientsArea = false
            self.reload(sections: [.recipientsLabel, .recipients(.to), .recipients(.cc), .recipients(.bcc)])
        }
    }

    private func hideRecipientLabel() {
        self.shouldShowEmailRecipientsLabel = false
        self.reload(sections: [.recipientsLabel, .recipients(.to), .recipients(.cc), .recipients(.bcc)])
    }

    private func subjectNode() -> ASCellNode {
        TextFieldCellNode(
            input: decorator.styledTextFieldInput(
                with: "compose_subject".localized,
                accessibilityIdentifier: "aid-subject-text-field"
            )
        ) { [weak self] event in
            switch event {
            case .editingChanged(let text), .didEndEditing(let text):
                self?.contextToSend.subject = text
            case .didBeginEditing:
                self?.userTappedOutSideRecipientsArea = true
                self?.showRecipientLabelIfNecessary()
            case .deleteBackward:
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
                accessibilityIdentifier: "aid-message-text-view"
            )
        ) { [weak self] event in
            guard let self = self else { return }
            switch event {
            case .didBeginEditing:
                self.userTappedOutSideRecipientsArea = true
                self.showRecipientLabelIfNecessary()
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
        let recipients = contextToSend.recipients(type: type)

        let shouldShowToggleButton = type == .to
            && recipients.isNotEmpty
            && !contextToSend.hasCcOrBccRecipients

        return RecipientEmailsCellNode(
            recipients: recipients.map(RecipientEmailsCellNode.Input.init),
            type: type.rawValue,
            height: decorator.recipientsNodeHeight(type: type) ?? Constants.minRecipientsPartHeight,
            isToggleButtonRotated: shouldShowAllRecipientTypes,
            toggleButtonAction: shouldShowToggleButton ? { [weak self] in
                guard type == .to else { return }
                self?.toggleRecipientsList()
            } : nil)
            .onLayoutHeightChanged { [weak self] layoutHeight in
                self?.decorator.updateRecipientsNode(
                    layoutHeight: layoutHeight,
                    type: type,
                    reload: { sections in
                        DispatchQueue.main.async {
                            self?.reload(sections: sections)
                        }
                    }
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

    private func recipientInput(type: RecipientType) -> ASCellNode {
        let recipients = contextToSend.recipients(type: type)
        let shouldShowToggleButton = type == .to
            && contextToSend.recipients(type: .to).isEmpty
            && !contextToSend.hasCcOrBccRecipients

        return RecipientEmailTextFieldNode(
            input: decorator.styledTextFieldInput(
                with: "",
                keyboardType: .emailAddress,
                accessibilityIdentifier: "aid-recipients-text-field-\(type.rawValue)"
            ),
            hasRecipients: recipients.isNotEmpty,
            type: type.rawValue,
            action: { [weak self] action in
                self?.handle(textFieldAction: action, for: type)
            },
            isToggleButtonRotated: shouldShowAllRecipientTypes,
            toggleButtonAction: shouldShowToggleButton ? { [weak self] in
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
            if type == selectedRecipientType {
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
                self?.reload(sections: [.attachments])
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
        case let .editingChanged(text): handleEditingChanged(with: text)
        case .didBeginEditing: handleDidBeginEditing(recipientType: recipientType)
        }
    }

    private func handleEndEditingAction(with email: String?, name: String? = nil, for recipientType: RecipientType) {
        guard shouldEvaluateRecipientInput,
              let email = email, email.isNotEmpty
        else { return }

        let recipients = contextToSend.recipients(type: recipientType)

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

        let newRecipient = ComposeMessageRecipient(
            email: email,
            name: name,
            type: recipientType,
            state: decorator.recipientIdleState
        )

        let indexOfRecipient: Int

        let indexPath = recipientsIndexPath(type: recipientType, part: .list)

        if let index = idleRecipients.firstIndex(where: { $0.email == newRecipient.email }) {
            // recipient already in list
            evaluate(recipient: newRecipient)
            indexOfRecipient = index
        } else {
            // add new recipient
            contextToSend.add(recipient: newRecipient)

            if let indexPath = indexPath {
                node.reloadRows(at: [indexPath], with: .automatic)
            }

            evaluate(recipient: newRecipient)

            // scroll to the latest recipient
            indexOfRecipient = recipients.endIndex - 1
        }

        if let indexPath = indexPath,
           let emailsNode = node.nodeForRow(at: indexPath) as? RecipientEmailsCellNode {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                emailsNode.collectionNode.scrollToItem(
                    at: IndexPath(row: indexOfRecipient, section: 0),
                    at: .bottom,
                    animated: true
                )
            }
        }

        node.view.keyboardDismissMode = .interactive
        search.send("")
        userFinishedSearching = true

        updateState(with: .main)
    }

    private func recipientsIndexPath(type: RecipientType, part: RecipientPart) -> IndexPath? {
        guard let section = sectionsList.firstIndex(of: .recipients(type)) else { return nil }
        return IndexPath(row: part.rawValue, section: section)
    }

    private func recipientsTextField(type: RecipientType) -> TextFieldNode? {
        guard let indexPath = recipientsIndexPath(type: type, part: .input) else { return nil }
        return (node.nodeForRow(at: indexPath) as? RecipientEmailTextFieldNode)?.textField
    }

    private func handleBackspaceAction(with textField: UITextField, for recipientType: RecipientType) {
        guard textField.text == "" else { return }

        var recipients = contextToSend.recipients(type: recipientType)

        let selectedRecipients = recipients.filter { $0.state.isSelected }

        guard selectedRecipients.isEmpty else {
            let notSelectedRecipients = recipients.filter { !$0.state.isSelected }
            contextToSend.set(recipients: notSelectedRecipients, for: recipientType)
            reload(sections: [.recipients(.to), .password])

            if let indexPath = recipientsIndexPath(type: recipientType, part: .list),
               let inputIndexPath = recipientsIndexPath(type: recipientType, part: .input) {
                node.reloadRows(at: [indexPath, inputIndexPath], with: .automatic)
            }

            return
        }

        if var lastRecipient = recipients.popLast() {
            // select last recipient in a list
            lastRecipient.state = self.decorator.recipientSelectedState
            recipients.append(lastRecipient)
            contextToSend.set(recipients: recipients, for: recipientType)

            if let indexPath = recipientsIndexPath(type: recipientType, part: .list) {
                node.reloadRows(at: [indexPath], with: .automatic)
            }
        } else {
            // dismiss keyboard if no recipients left
            textField.resignFirstResponder()
        }
    }

    private func handleEditingChanged(with text: String?) {
        search.send(text ?? "")
    }

    private func handleDidBeginEditing(recipientType: RecipientType) {
        selectedRecipientType = recipientType
        node.view.keyboardDismissMode = .none
    }

    private func toggleRecipientsList() {
        shouldShowAllRecipientTypes.toggle()
        reload(sections: [.recipients(.cc), .recipients(.bcc)])
    }
}

// MARK: - Action Handling
extension ComposeViewController {
    private func searchEmail(with query: String) {
        Task {
            do {
                let cloudRecipients = try await service.searchContacts(query: query)
                let localRecipients = try localContactsProvider.searchRecipients(query: query)

                let recipients = (cloudRecipients + localRecipients)
                                    .unique()
                                    .sorted()

                updateState(with: .searchEmails(recipients))
            } catch {
                showAlert(message: error.localizedDescription)
            }
        }
    }

    private func evaluate(recipient: ComposeMessageRecipient, showRecipientLabelFlag: Bool = true) {
        guard recipient.email.isValidEmail else {
            updateRecipient(
                email: recipient.email,
                state: decorator.recipientInvalidEmailState
            )
            return
        }

        Task {
            isRecipientLoading = true
            var localContact: RecipientWithSortedPubKeys?
            do {
                if let contact = try await service.findLocalContact(with: recipient.email) {
                    localContact = contact
                    handleEvaluation(for: contact)
                }

                let contact = Recipient(recipient: recipient)
                let contactWithFetchedKeys = try await service.fetchPubKeys(for: contact)
                handleEvaluation(for: contactWithFetchedKeys)
                isRecipientLoading = false
                if showRecipientLabelFlag {
                    showRecipientLabelIfNecessary()
                }
            } catch {
                handleEvaluation(error: error, with: recipient.email, contact: localContact)
                isRecipientLoading = false
                if showRecipientLabelFlag {
                    showRecipientLabelIfNecessary()
                }
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

    private func handleEvaluation(error: Error, with email: String, contact: RecipientWithSortedPubKeys?) {
        let recipientState: RecipientState = {
            if let contact = contact, contact.keyState == .active {
                return getRecipientState(from: contact)
            }
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
                reload(sections: [.password])

                if let listIndexPath = recipientsIndexPath(type: recipient.type, part: .list) {
                    node.reloadRows(at: [listIndexPath], with: .automatic)
                }
            }
        }
    }

    private func handleRecipientSelection(with indexPath: IndexPath, type: RecipientType) {
        guard let recipient = contextToSend.recipient(at: indexPath.row, type: type) else { return }

        let isSelected = recipient.state.isSelected
        let state = isSelected ? decorator.recipientIdleState : decorator.recipientSelectedState
        contextToSend.update(recipient: recipient.email, type: type, state: state)

        if isSelected {
            evaluate(recipient: recipient)
        }

        if let listIndexPath = recipientsIndexPath(type: type, part: .list) {
            node.reloadRows(at: [listIndexPath], with: .automatic)
        }

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
                contextToSend.remove(recipient: recipient.email, type: type)

                if let listIndexPath = recipientsIndexPath(type: type, part: .list) {
                    node.reloadRows(at: [listIndexPath], with: .automatic)
                }
            }
        }
    }

    // MARK: - Message password
    private func setMessagePassword() {
        Task {
            contextToSend.messagePassword = await enterMessagePassword()
            reload(sections: [.password])
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
        if case .searchEmails = newState, self.isPreviousSearchStateEmpty || self.userFinishedSearching {
            self.isPreviousSearchStateEmpty = false
            self.userFinishedSearching = false
            return
        }

        state = newState

        switch state {
        case .main:
            sectionsList = Section.recipientsSections + [.recipientsLabel, .password, .compose, .attachments]
            node.reloadData()
        case .searchEmails:
            let previousSectionsCount = sectionsList.count
            sectionsList = Section.recipientsSections + [.searchResults, .contacts]

            let deletedSectionsCount = previousSectionsCount - sectionsList.count

            let sectionsToReload: [Section]
            if let type = selectedRecipientType {
                sectionsToReload = sectionsList.filter { $0 != .recipients(type) }
            } else {
                sectionsToReload = sectionsList
            }

            node.performBatchUpdates {
                if deletedSectionsCount > 0 {
                    let sectionsToDelete = sectionsList.count..<sectionsList.count + deletedSectionsCount
                    node.deleteSections(IndexSet(sectionsToDelete), with: .none)
                }

                reload(sections: sectionsToReload)
            }
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
        reload(sections: [.attachments])
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
        reload(sections: [.attachments])
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
        reload(sections: [.attachments])
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
                reload(sections: [.contacts])
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
    private let pubLookup: PubLookupType
    private let localContactsProvider: LocalContactsProviderType
    private let cloudContactProvider: CloudContactsProvider

    init(composeMessageService: ComposeMessageService,
         localContactsProvider: LocalContactsProviderType,
         pubLookup: PubLookupType,
         cloudContactProvider: CloudContactsProvider) {
        self.composeMessageService = composeMessageService
        self.localContactsProvider = localContactsProvider
        self.pubLookup = pubLookup
        self.cloudContactProvider = cloudContactProvider
    }

    func encryptAndSend(message: SendableMsg, threadId: String?) async throws {
        try await composeMessageService.encryptAndSend(
            message: message,
            threadId: threadId
        )
    }

    func searchContacts(query: String) async throws -> [Recipient] {
        return try await cloudContactProvider.searchContacts(query: query)
    }

    func findLocalContact(with email: String) async throws -> RecipientWithSortedPubKeys? {
        return try await localContactsProvider.searchRecipient(with: email)
    }

    func fetchPubKeys(for recipient: Recipient) async throws -> RecipientWithSortedPubKeys {
        return try await pubLookup.fetchRemoteUpdateLocal(with: recipient)
    }
}
