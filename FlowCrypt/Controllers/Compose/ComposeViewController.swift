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
 * - Or from *ThreadDetailsViewController* controller by tapping on *reply* or *forward*
 **/
final class ComposeViewController: TableNodeViewController {

    enum Constants {
        static let endTypingCharacters = [",", "\n", ";"]
        static let minRecipientsPartHeight: CGFloat = 32
    }

    struct ComposedDraft: Equatable {
        let input: ComposeMessageInput
        let contextToSend: ComposeMessageContext
    }

    enum State {
        case main, searchEmails([Recipient])
    }

    enum Section: Hashable {
        case passphrase, recipientsLabel, recipients(RecipientType), password, compose, attachments, searchResults, contacts

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
    var userTappedOutSideRecipientsArea = false
    var shouldShowEmailRecipientsLabel = false
    let appContext: AppContextWithUser
    let composeMessageService: ComposeMessageService
    var decorator: ComposeViewDecorator
    let localContactsProvider: LocalContactsProviderType
    let messageService: MessageService
    let pubLookup: PubLookupType
    let googleUserService: GoogleUserServiceType
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

    var signingKeyWithMissingPassphrase: Keypair?
    var messagePasswordAlertController: UIAlertController?
    lazy var alertsFactory = AlertsFactory()

    private var didLayoutSubviews = false
    private var topContentInset: CGFloat {
        navigationController?.navigationBar.frame.maxY ?? 0
    }

    var selectedRecipientType: RecipientType? = .to
    var shouldShowAllRecipientTypes = false
    var popoverVC: ComposeRecipientPopupViewController!

    var sectionsList: [Section] = []
    var composeTextNode: ASCellNode!
    var composeSubjectNode: ASCellNode!
    var sendAsList: [SendAsModel] = []

    init(
        appContext: AppContextWithUser,
        decorator: ComposeViewDecorator = ComposeViewDecorator(),
        input: ComposeMessageInput = .empty,
        composeMessageService: ComposeMessageService? = nil,
        messageService: MessageService? = nil,
        filesManager: FilesManagerType = FilesManager(),
        photosManager: PhotosManagerType = PhotosManager(),
        keyMethods: KeyMethodsType = KeyMethods()
    ) async throws {
        self.appContext = appContext
        self.input = input
        self.decorator = decorator
        let clientConfiguration = try await appContext.clientConfigurationService.configuration

        self.localContactsProvider = LocalContactsProvider(
            encryptedStorage: appContext.encryptedStorage
        )
        self.googleUserService = GoogleUserService(
            currentUserEmail: appContext.user.email,
            appDelegateGoogleSessionContainer: UIApplication.shared.delegate as? AppDelegate,
            shouldRunWarmupQuery: true
        )
        let draftGateway = try appContext.getRequiredMailProvider().draftGateway
        self.composeMessageService = composeMessageService ?? ComposeMessageService(
            appContext: appContext,
            keyMethods: keyMethods,
            draftGateway: draftGateway
        )
        self.filesManager = filesManager
        self.photosManager = photosManager
        self.pubLookup = PubLookup(
            clientConfiguration: clientConfiguration,
            localContactsProvider: self.localContactsProvider
        )
        self.router = appContext.globalRouter
        self.clientConfiguration = clientConfiguration

        let mailProvider = try appContext.getRequiredMailProvider()
        self.messageService = try messageService ?? MessageService(
            localContactsProvider: localContactsProvider,
            pubLookup: PubLookup(clientConfiguration: clientConfiguration, localContactsProvider: localContactsProvider),
            keyAndPassPhraseStorage: appContext.keyAndPassPhraseStorage,
            messageProvider: try mailProvider.messageProvider,
            combinedPassPhraseStorage: appContext.combinedPassPhraseStorage
        )

        self.sendAsList = try await appContext.getSendAsService()
            .fetchList(isForceReload: false, for: appContext.user)
            .filter { $0.verificationStatus == .accepted || $0.isDefault }

        self.contextToSend = ComposeMessageContext(
            sender: appContext.user.email,
            subject: input.subject,
            attachments: input.attachments
        )
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
        setupNodes()
        observeKeyboardNotifications()
        observerAppStates()
        observeComposeUpdates()
        fillDataFromInput()
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

extension ComposeViewController: FilesManagerPresenter {}

// update draft, don't create a new one each time
// decrypt draft body
// add delete button for drafts in compose view
