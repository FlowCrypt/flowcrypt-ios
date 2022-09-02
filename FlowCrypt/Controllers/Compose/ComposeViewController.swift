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

    internal enum Constants {
        static let endTypingCharacters = [",", "\n", ";"]
        static let minRecipientsPartHeight: CGFloat = 32
    }

    internal struct ComposedDraft: Equatable {
        let input: ComposeMessageInput
        let contextToSend: ComposeMessageContext
    }

    internal enum State {
        case main, searchEmails([Recipient])
    }

    enum Section: Hashable {
        case recipientsLabel, recipients(RecipientType), password, compose, attachments, searchResults, contacts

        static var recipientsSections: [Section] {
            RecipientType.allCases.map { Section.recipients($0) }
        }
    }

    enum RefreshType {
        case delete, reload, add, scrollToBottom
    }

    internal enum ComposePart: Int, CaseIterable {
        case topDivider, subject, subjectDivider, text
    }

    internal var shouldDisplaySearchResult = false
    internal var userTappedOutSideRecipientsArea = false
    internal var shouldShowEmailRecipientsLabel = false
    internal let appContext: AppContextWithUser
    internal let composeMessageService: ComposeMessageService
    internal var decorator: ComposeViewDecorator
    internal let localContactsProvider: LocalContactsProviderType
    internal let pubLookup: PubLookupType
    internal let googleUserService: GoogleUserServiceType
    internal let filesManager: FilesManagerType
    internal let photosManager: PhotosManagerType
    internal let router: GlobalRouterType

    private let clientConfiguration: ClientConfiguration
    internal var isMessagePasswordSupported: Bool {
        return clientConfiguration.isUsingFes
    }

    internal let search = PassthroughSubject<String, Never>()
    internal var cancellable = Set<AnyCancellable>()

    internal var input: ComposeMessageInput
    internal var contextToSend: ComposeMessageContext

    internal var state: State = .main
    internal var shouldEvaluateRecipientInput = true

    internal weak var saveDraftTimer: Timer?
    internal var composedLatestDraft: ComposedDraft?

    internal lazy var alertsFactory = AlertsFactory()
    internal var messagePasswordAlertController: UIAlertController?
    private var didLayoutSubviews = false
    private var topContentInset: CGFloat {
        navigationController?.navigationBar.frame.maxY ?? 0
    }

    internal var selectedRecipientType: RecipientType? = .to
    internal var shouldShowAllRecipientTypes = false
    internal var popoverVC: ComposeRecipientPopupViewController!

    internal var sectionsList: [Section] = []
    var composeTextNode: ASCellNode!
    var composeSubjectNode: ASCellNode!
    var fromCellNode: RecipientFromCellNode!
    var sendAsList: [SendAsModel] = []

    init(
        appContext: AppContextWithUser,
        decorator: ComposeViewDecorator = ComposeViewDecorator(),
        input: ComposeMessageInput = .empty,
        composeMessageService: ComposeMessageService? = nil,
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
        self.composeMessageService = composeMessageService ?? ComposeMessageService(
            appContext: appContext,
            keyMethods: keyMethods
        )
        self.filesManager = filesManager
        self.photosManager = photosManager
        self.pubLookup = PubLookup(
            clientConfiguration: clientConfiguration,
            localContactsProvider: self.localContactsProvider
        )
        self.router = appContext.globalRouter
        self.clientConfiguration = clientConfiguration

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

    func update(with message: Message) {
        if let sender = message.sender?.email {
            contextToSend.sender = sender
        }

        contextToSend.subject = message.subject
        contextToSend.message = message.raw

        for recipient in message.to {
            add(recipient: recipient, type: .to)
        }
        for recipient in message.cc {
            add(recipient: recipient, type: .cc)
        }
        for recipient in message.bcc {
            add(recipient: recipient, type: .bcc)
        }
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
