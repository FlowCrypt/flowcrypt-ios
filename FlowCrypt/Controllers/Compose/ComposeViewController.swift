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
 * - Or from *ThreadDetailsViewController* controller by tapping on *reply* or *forward*
 **/
final class ComposeViewController: TableNodeViewController {

    enum Constants {
        static let endTypingCharacters = [",", "\n", ";"]
        static let minRecipientsPartHeight: CGFloat = 32
    }

    enum State {
        case main, searchEmails([Recipient])
    }

    enum Section: Hashable {
        case recipientsLabel, recipients(RecipientType), password, compose, attachments, searchResults, contacts

        static var recipientsSections: [Section] {
            RecipientType.allCases.map { Self.recipients($0) }
        }
    }

    enum RefreshType {
        case delete, reload, add, scrollToBottom
    }

    enum ComposePart: Int, CaseIterable {
        case topDivider, subject, subjectDivider, text
    }

    var shouldDisplaySearchResult = false
    var draftSaveRetryCount = 0
    var shouldSaveCurrentDraft = true
    var userTappedOutSideRecipientsArea = false
    var shouldShowEmailRecipientsLabel = false
    let appContext: AppContextWithUser
    let composeMessageHelper: ComposeMessageHelper
    var decorator: ComposeViewDecorator
    let localContactsProvider: LocalContactsProviderType
    let messageHelper: MessageHelper
    let pubLookup: PubLookupType
    let googleAuthManager: GoogleAuthManagerType
    var contactsProvider: ContactsProviderType
    let filesManager: FilesManagerType
    let photosManager: PhotosManagerType
    let router: GlobalRouterType

    private let clientConfiguration: ClientConfiguration
    var isMessagePasswordSupported: Bool { clientConfiguration.isUsingFes }

    let search = PassthroughSubject<String, Never>()
    var cancellable = Set<AnyCancellable>()

    var input: ComposeMessageInput
    var contextToSend: ComposeMessageContext

    var state: State = .main
    var shouldEvaluateRecipientInput = true

    weak var saveDraftTimer: Timer?
    var composedLatestDraft: ComposedDraft?

    var messagePasswordAlertController: UIAlertController?
    let alertsFactory: AlertsFactory

    var didFinishSetup = false {
        didSet {
            if didFinishSetup { setupTextNode() }
        }
    }

    private var didLayoutSubviews = false
    private var topContentInset: CGFloat {
        navigationController?.navigationBar.frame.maxY ?? 0
    }

    var selectedRecipientType: RecipientType? = .to
    var shouldShowAllRecipientTypes = false
    var popoverVC: ComposeRecipientPopupViewController!

    var sectionsList: [Section] = []
    var composeTextNode: ASCellNode?
    var composeSubjectNode: ASCellNode?
    var sendAsList: [SendAsModel] = []

    let handleAction: ((ComposeMessageAction) -> Void)?

    init(
        appContext: AppContextWithUser,
        decorator: ComposeViewDecorator = ComposeViewDecorator(),
        input: ComposeMessageInput = .empty,
        composeMessageHelper: ComposeMessageHelper? = nil,
        messageHelper: MessageHelper? = nil,
        filesManager: FilesManagerType = FilesManager(),
        photosManager: PhotosManagerType = PhotosManager(),
        keyMethods: KeyMethodsType = KeyMethods(),
        handleAction: ((ComposeMessageAction) -> Void)? = nil
    ) async throws {
        self.appContext = appContext
        self.input = input
        self.decorator = decorator
        let clientConfiguration = try await appContext.clientConfigurationProvider.configuration

        self.localContactsProvider = LocalContactsProvider(
            encryptedStorage: appContext.encryptedStorage
        )
        self.googleAuthManager = GoogleAuthManager(
            appDelegateGoogleSessionContainer: UIApplication.shared.delegate as? AppDelegate
        )
        self.contactsProvider = GoogleContactsProvider(authorization: self.googleAuthManager.authorization(for: appContext.user.email))

        let draftsApiClient = try appContext.getRequiredMailProvider().draftsApiClient

        if let composeMessageHelper {
            self.composeMessageHelper = composeMessageHelper
        } else {
            self.composeMessageHelper = ComposeMessageHelper(
                appContext: appContext,
                keyMethods: keyMethods,
                draftsApiClient: draftsApiClient
            )
        }

        self.alertsFactory = AlertsFactory(encryptedStorage: appContext.encryptedStorage)
        self.filesManager = filesManager
        self.photosManager = photosManager
        self.pubLookup = PubLookup(
            clientConfiguration: clientConfiguration,
            localContactsProvider: self.localContactsProvider
        )
        self.router = appContext.globalRouter
        self.clientConfiguration = clientConfiguration

        let mailProvider = try appContext.getRequiredMailProvider()
        self.messageHelper = try messageHelper ?? MessageHelper(
            localContactsProvider: localContactsProvider,
            pubLookup: PubLookup(
                clientConfiguration: clientConfiguration,
                localContactsProvider: localContactsProvider
            ),
            keyAndPassPhraseStorage: appContext.keyAndPassPhraseStorage,
            messageProvider: try mailProvider.messageProvider,
            combinedPassPhraseStorage: appContext.combinedPassPhraseStorage
        )

        self.sendAsList = try await appContext.getSendAsProvider()
            .fetchList(isForceReload: false, for: appContext.user)
            .filter { $0.verificationStatus == .accepted || $0.isDefault }

        self.contextToSend = ComposeMessageContext(
            sender: appContext.user.email,
            subject: input.subject,
            attachments: input.attachments
        )
        self.handleAction = handleAction
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
        setupSubjectNode()
        observeKeyboardNotifications()
        observerAppStates()
        observeComposeUpdates()
        fillDataFromInput()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        node.view.endEditing(true)
        stopDraftTimer(withSave: false)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        startDraftTimer(withFire: true)

        guard shouldEvaluateRecipientInput else {
            shouldEvaluateRecipientInput = true
            return
        }

        for cancellable in cancellable {
            cancellable.cancel()
        }

        setupSearch()
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

    func add(recipient: Recipient, type: RecipientType) {
        let composeRecipient = ComposeMessageRecipient(
            email: recipient.email,
            name: recipient.name,
            type: type,
            state: decorator.recipientIdleState
        )
        contextToSend.add(recipient: composeRecipient)
        evaluate(recipient: composeRecipient)
    }

    private func observeComposeUpdates() {
        composeMessageHelper.onStateChanged { [weak self] state in
            DispatchQueue.main.async {
                self?.updateSpinner(with: state)
            }
        }
    }

    private func updateSpinner(with state: ComposeMessageHelper.State) {
        switch state {
        case let .progressChanged(progress):
            if progress < 1 {
                showSpinnerWithProgress(state.message ?? "\(progress)", progress: progress)
            } else {
                showSpinner("sending_title".localized)
            }
        case .startComposing, .validatingMessage:
            showSpinner(state.message ?? "")
        case .idle, .messageSent:
            hideSpinner()
        }
    }

    @objc override func adjustForKeyboard(notification: Notification) {
        let height = self.keyboardHeight(from: notification)
        node.contentInset.bottom = height + 8

        guard let textView = node.visibleNodes.compactMap({ $0 as? TextViewCellNode }).first?.textView.textView,
              let selectedRange = textView.selectedTextRange
        else { return }

        let rect = textView.caretRect(for: selectedRange.start)
        node.view.scrollRectToVisible(rect, animated: true)
    }
}

extension ComposeViewController: FilesManagerPresenter {}
