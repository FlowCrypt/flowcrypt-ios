//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit
import Combine
import FlowCryptCommon
import FlowCryptUI

/**
 * View controller to compose the message and send it
 * - User can be redirected here from *InboxViewController* by tapping on *+*
 * - Or from *MessageViewController* controller by tapping on *reply*
 */
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

    private let searchThrottler = Throttler(seconds: 1)
    private let cloudContactProvider: CloudContactsProvider
    private let userDefaults: UserDefaults

    private let email: String

    private var cancellable = Set<AnyCancellable>()
    private var input: ComposeMessageInput
    private var contextToSend = ComposeMessageContext()

    private var state: State = .main

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
        photosManager: PhotosManagerType = PhotosManager()
    ) {
        self.email = email
        self.notificationCenter = notificationCenter
        self.input = input
        self.decorator = decorator
        self.cloudContactProvider = cloudContactProvider
        self.userDefaults = userDefaults
        self.contactsService = contactsService
        self.composeMessageService = composeMessageService
        self.filesManager = filesManager
        self.photosManager = photosManager
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
        setupReply()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        node.view.endEditing(true)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // temporary disable search contacts - https://github.com/FlowCrypt/flowcrypt-ios/issues/217
        // showScopeAlertIfNeeded()
        cancellable.forEach { $0.cancel() }
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
        sendMessage()
    }
}

// MARK: - Message Sending

extension ComposeViewController {
    private func sendMessage() {
        view.endEditing(true)
        showSpinner("sending_title".localized)
        navigationItem.rightBarButtonItem?.isEnabled = false

        composeMessageService.validateMessage(
            input: input,
            contextToSend: contextToSend,
            email: email
        )
        .publisher
        .flatMap(composeMessageService.encryptAndSend)
        .sinkFuture(
            receiveValue: { [weak self] in
                self?.handleSuccessfullySentMessage()
            },
            receiveError: { [weak self] error in
                self?.handle(error: error)
            })
        .store(in: &cancellable)
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
        let nodeHeight = tableNode.frame.size.height
            - (navigationController?.navigationBar.frame.size.height ?? 0.0)
            - safeAreaWindowInsets.top
            - safeAreaWindowInsets.bottom
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
                case .text: return self.textNode(with: nodeHeight)
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
            guard case let .didEndEditing(text) = event else { return }
            self?.contextToSend.subject = text
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
            $0.attributedText = decorator.styledTitle(with: input.subjectReplyTitle)
        }
    }

    private func textNode(with nodeHeight: CGFloat) -> ASCellNode {
        return TextViewCellNode(
            decorator.styledTextViewInput(with: 40),
            action: { [weak self] event in
                guard case let .didEndEditing(text) = event else { return }
                self?.contextToSend.message = text?.string
            })
            .then {
                guard self.input.isReply else { return }
                $0.textView.attributedText = self.decorator.styledReplyQuote(with: self.input)
                $0.becomeFirstResponder()
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
            )
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
//        temporary disable search contacts - https://github.com/FlowCrypt/flowcrypt-ios/issues/217
//        guard let text = text, text.isNotEmpty else {
//            updateState(with: .main)
//            return
//        }
//
//        searchThrottler.throttle { [weak self] in
//            self?.searchEmail(with: text)
//        }
    }

    private func handleDidBeginEditing() {
        node.view.keyboardDismissMode = .none
    }
}

// MARK: - Action Handling
extension ComposeViewController {
    private func searchEmail(with query: String) {
        cloudContactProvider.searchContacts(query: query)
            .then(on: .main) { [weak self] emails in
                let state: State = emails.isNotEmpty
                    ? .searchEmails(emails)
                    : .main
                self?.updateState(with: state)
            }
    }

    private func evaluate(recipient: ComposeMessageRecipient) {
        guard isValid(email: recipient.email) else {
            updateRecipientWithNew(state: self.decorator.recipientErrorState, for: .left(recipient))
            return
        }

        contactsService.searchContact(with: recipient.email)
            .then(on: .main) { [weak self] _ in
                self?.handleEvaluation(for: recipient)
            }
            .catch(on: .main) { [weak self] error in
                self?.handleEvaluation(error: error, with: recipient)
            }
    }

    private func handleEvaluation(for recipient: ComposeMessageRecipient) {
        updateRecipientWithNew(
            state: decorator.recipientKeyFoundState,
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
        case .keyFound, .keyNotFound, .selected:
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

    private func isValid(email: String) -> Bool {
        let emailFormat = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailFormat)
        return emailPredicate.evaluate(with: email)
    }
}

// MARK: - State Handling
extension ComposeViewController {
    private func updateState(with newState: State) {
        state = newState
        node.reloadSections(IndexSet(integer: 0), with: .fade)
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
        contextToSend.attachments.append(attachment)
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

        let attachment: ComposeMessageAttachment?
        switch picker.sourceType {
        case .camera:
            attachment = ComposeMessageAttachment(cameraSourceMediaInfo: info)
        case .photoLibrary:
            attachment = ComposeMessageAttachment(librarySourceMediaInfo: info)
        default: fatalError("No other image picker's sources should be used")
        }
        guard let attachment = attachment else {
            showAlert(message: "files_picking_photos_error_message".localized)
            return
        }
        contextToSend.attachments.append(attachment)
        node.reloadSections(IndexSet(integer: 2), with: .automatic)
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
            title: "setttings".localized,
            style: .default
        ) { _ in
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
        }
        alert.addAction(okAction)
        alert.addAction(settingsAction)

        present(alert, animated: true, completion: nil)
    }
}

// temporary disable search contacts
// https://github.com/FlowCrypt/flowcrypt-ios/issues/217
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
