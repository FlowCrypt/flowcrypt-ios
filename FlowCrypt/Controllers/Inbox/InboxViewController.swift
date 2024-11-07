//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptCommon
import FlowCryptUI

@MainActor
class InboxViewController: ViewController {
    lazy var logger = Logger.nested(Self.self)

    private let numberOfInboxItemsToLoad: Int

    let appContext: AppContextWithUser
    let tableNode: ASTableNode

    let decorator: InboxViewDecorator
    let messageOperationsApiClient: MessageOperationsApiClient
    let threadOperationsApiClient: MessagesThreadOperationsApiClient
    let messageActionsHelper: MessageActionsHelper
    private let refreshControl = UIRefreshControl()
    private lazy var composeButton = AddButtonNode(identifier: "aid-compose-message-button") { [weak self] in
        self?.btnComposeTap()
    }

    let inboxDataApiClient: InboxDataApiClient
    let viewModel: InboxViewModel
    var inboxInput: [InboxItem] = []
    var selectedInboxItems: [InboxItem] {
        return inboxInput.filter(\.isSelected)
    }

    var state: InboxViewController.State = .idle
    var inboxTitle: String {
        viewModel.folderName.isEmpty ? "Inbox" : viewModel.folderName
    }

    var shouldShowEmptyView: Bool {
        inboxInput.isNotEmpty && (["SPAM", "TRASH"].contains(viewModel.path))
    }

    var path: String { viewModel.path }

    // Search related variables
    private var isSearch = false
    var shouldBeginFetch = true
    var searchedExpression = ""

    private var isVisible = false
    private var didLayoutSubviews = false

    init(
        appContext: AppContextWithUser,
        viewModel: InboxViewModel,
        numberOfInboxItemsToLoad: Int = 50,
        apiClient: InboxDataApiClient,
        decorator: InboxViewDecorator = InboxViewDecorator(),
        isSearch: Bool = false
    ) async throws {
        self.appContext = appContext
        self.viewModel = viewModel
        self.numberOfInboxItemsToLoad = numberOfInboxItemsToLoad
        self.inboxDataApiClient = apiClient

        let mailProvider = try appContext.getRequiredMailProvider()
        self.messageOperationsApiClient = try mailProvider.messageOperationsApiClient
        self.threadOperationsApiClient = try mailProvider.threadOperationsApiClient
        self.messageActionsHelper = try await MessageActionsHelper(
            appContext: appContext
        )
        self.decorator = decorator
        self.tableNode = TableNode()
        self.isSearch = isSearch

        super.init(node: ASDisplayNode())
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressGesture))
        tableNode.view.addGestureRecognizer(longPressGesture)
        if !self.isSearch {
            setupUI()
            setupNavigationBar()
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadThreadList),
            name: .reloadThreadList,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        isVisible = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isVisible = false
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard !didLayoutSubviews else { return }

        setupElements()

        didLayoutSubviews = true
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard didLayoutSubviews else { return }

        setupElements()
        tableNode.reloadData()
    }
}

// MARK: - UI
extension InboxViewController {
    @objc func reloadThreadList() {
        showSpinner()
        refresh()
    }

    private func setupUI() {
        title = inboxTitle

        setupTableNode()
        node.addSubnode(composeButton)
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
    }

    func setupTableNode() {
        tableNode.do {
            $0.delegate = self
            $0.dataSource = self
            $0.leadingScreensForBatching = 1
            $0.accessibilityIdentifier = "aid-inbox-list"
            $0.view.refreshControl = refreshControl
            node.addSubnode($0)
        }
    }

    @objc public func setupNavigationBar() {
        navigationItem.setAccessibility(id: inboxTitle)
        navigationItem.rightBarButtonItem = NavigationBarItemsView(
            with: [
                NavigationBarItemsView.Input(
                    image: UIImage(systemName: "questionmark.circle"),
                    accessibilityId: "aid-help-btn"
                ) { [weak self] in self?.handleInfoTap() },
                NavigationBarItemsView.Input(
                    image: UIImage(systemName: "magnifyingglass"),
                    accessibilityId: "aid-search-btn"
                ) { [weak self] in self?.handleSearchTap() }
            ]
        )
        navigationItem.leftBarButtonItem = getSideMenuNavButton()
    }

    func setupThreadSelectNavigationBar() {
        navigationItem.setAccessibility(id: "x_selected".localizeWithArguments("\(selectedInboxItems.count)"))

        // For normal folders (not Spam and trash folder), display moveToTrash
        var actions: [MessageAction] = shouldShowEmptyView ? [.permanentlyDelete] : [.moveToTrash]
        let selectedInInbox = inboxInput.contains { $0.isSelected && $0.isInbox }
        let selectedUnread = inboxInput.contains { $0.isSelected && !$0.isRead }

        if selectedInInbox, !shouldShowEmptyView {
            actions.append(.archive)
        } else if !selectedInInbox {
            actions.append(.moveToInbox)
        }
        actions.append(selectedUnread ? .markAsRead : .markAsUnread)

        let items = actions.map { createNavigationBarButton(action: $0) }
        navigationItem.rightBarButtonItem = NavigationBarItemsView(with: items)
        navigationItem.leftBarButtonItem = .defaultBackButton { [weak self] in
            guard let self else { return }
            resetSelectedThreads()
            setupNavigationBar()
        }
    }

    private func resetSelectedThreads() {
        inboxInput.indices
            .filter { inboxInput[$0].isSelected }
            .forEach { index in
                inboxInput[index].isSelected = false
                reloadMessage(index: index, animationDuration: 0)
            }
    }

    private func createNavigationBarButton(action: MessageAction) -> NavigationBarItemsView.Input {
        .init(
            image: action.image,
            accessibilityId: action.accessibilityIdentifier
        ) { [weak self] in
            guard let self else { return }
            perform(action: action, inboxItems: selectedInboxItems)
        }
    }

    private func setupElements() {
        tableNode.frame = node.bounds

        if isSearch { return }

        let offset: CGFloat = 16

        composeButton.frame.origin = CGPoint(
            x: node.bounds.maxX - offset - .addButtonSize,
            y: node.bounds.maxY - offset - .addButtonSize - safeAreaWindowInsets.bottom
        )
    }
}

// MARK: - Helpers
extension InboxViewController {
    private func currentMessagesListPagination(from number: Int? = nil) throws -> MessagesListPagination {
        try appContext
            .getRequiredMailProvider()
            .currentMessagesListPagination(from: number, token: state.token)
    }

    private func messagesToLoad() -> Int {
        switch state {
        case let .fetched(.byNumber(totalNumberOfMessages)):
            guard let total = totalNumberOfMessages else {
                return numberOfInboxItemsToLoad
            }
            let from = inboxInput.count
            return min(numberOfInboxItemsToLoad, total - from)
        default:
            return numberOfInboxItemsToLoad
        }
    }
}

// MARK: - Functionality
extension InboxViewController {
    private func getSearchQuery() -> String? {
        let showOnlyPgp = UserDefaults.standard.bool(forKey: "SHOW_PGP_ONLY_FLAG")
        let pgpPattern = """
            ("-----BEGIN PGP MESSAGE-----" AND "-----END PGP MESSAGE-----") OR \
            ("-----BEGIN PGP SIGNED MESSAGE-----") OR \
            filename:({asc pgp gpg key})
        """
        let baseQuery = showOnlyPgp ? "\(pgpPattern) AND \(searchedExpression)" : searchedExpression
        guard baseQuery.isNotEmpty else { return nil }

        return baseQuery.hasPrefix("subject:") ? baseQuery : "\(baseQuery) OR subject:\(searchedExpression)"
    }

    func fetchAndRenderEmails(_ batchContext: ASBatchContext?) {
        Task {
            do {
                if isSearch {
                    state = .searching
                    await tableNode.reloadData()
                } else {
                    state = .fetching
                }

                let context = try await inboxDataApiClient.fetchInboxItems(
                    using: FetchMessageContext(
                        folderPath: isSearch ? nil : viewModel.path, // pass nil in search screen to search for all folders
                        count: numberOfInboxItemsToLoad,
                        searchQuery: getSearchQuery(),
                        pagination: currentMessagesListPagination()
                    )
                )
                state = .refresh
                handleEndFetching(with: context, context: batchContext)
                // Hide spinner after 0.5 seconds as it takes a while to reload view
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.hideSpinner()
                }
            } catch {
                handle(error: error)
            }
        }
    }

    private func loadMore(_ batchContext: ASBatchContext?) {
        guard state.canLoadMore, isVisible else {
            batchContext?.completeBatchFetching(true)
            return
        }

        Task {
            do {
                let pagination = try currentMessagesListPagination(from: inboxInput.count)
                state = .fetching

                let context = try await inboxDataApiClient.fetchInboxItems(
                    using: FetchMessageContext(
                        folderPath: viewModel.path,
                        count: messagesToLoad(),
                        pagination: pagination
                    )
                )
                state = .fetched(context.pagination)
                handleEndFetching(with: context, context: batchContext)
            } catch {
                handle(error: error)
            }
        }
    }

    func tableNode(_: ASTableNode, willBeginBatchFetchWith context: ASBatchContext) {
        if !shouldBeginFetch {
            context.completeBatchFetching(true)
            return
        }
        // Due to the inability to combine boolean and case checks, the following code is separated
        if case .empty = state {
            context.completeBatchFetching(true)
            return
        }
        context.beginBatchFetching()
        handleBeginFetching(context)
    }

    func handleBeginFetching(_ context: ASBatchContext?) {
        switch state {
        case .idle:
            fetchAndRenderEmails(context)
        case let .fetched(.byNumber(total)):
            guard inboxInput.count != total else {
                context?.completeBatchFetching(true)
                return
            }
            loadMore(context)
        case let .fetched(.byNextPage(token)):
            guard token != nil else {
                context?.completeBatchFetching(true)
                return
            }
            loadMore(context)
        case .empty:
            fetchAndRenderEmails(context)
            state = .idle
            DispatchQueue.main.async {
                self.refreshControl.endRefreshing()
                self.tableNode.reloadData()
            }
        case .fetching:
            break
        case .refresh:
            if let context, context.isFetching() {
                return
            }
            fetchAndRenderEmails(context)
        case .searching, .searchStart, .searchEmpty:
            context?.completeBatchFetching(true)
        default:
            break
        }
    }
}

// MARK: - Functionality Input
extension InboxViewController {

    private func handleEndFetching(with input: InboxContext, context: ASBatchContext?) {
        context?.completeBatchFetching(true)

        switch state {
        case .idle, .refresh:
            handleNew(input)
        case .fetched:
            handleFetched(input)
        default:
            break
        }
    }

    private func handleNew(_ input: InboxContext) {
        shouldBeginFetch = false
        inboxInput = input.data
        if inboxInput.isEmpty {
            state = isSearch ? .searchEmpty : .empty
        } else {
            state = .fetched(input.pagination)
        }
        refreshControl.endRefreshing()
        // Disable should begin fetch event while table node is reloaded
        // This is to prevent inbox initially load 2 pages of emails
        // (willBeginBatchFetchWith called right after initial inbox load and it triggered another page load before)
        tableNode.reloadData(completion: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.shouldBeginFetch = true
            }
        })
    }

    private func handleFetched(_ input: InboxContext) {
        let initialIndex = inboxInput.count

        let indexesToInsert = input.data.indices
            .map { IndexPath(row: initialIndex + $0, section: 0) }

        inboxInput.append(contentsOf: input.data)
        state = .fetched(input.pagination)

        DispatchQueue.main.async {
            self.refreshControl.endRefreshing()
            self.tableNode.insertRows(at: indexesToInsert, with: .automatic)
        }
    }

    private func handle(error: Error) {
        refreshControl.endRefreshing()

        switch error {
        case GmailApiError.invalidGrant:
            appContext.globalRouter.renderMissingPermissionsView(appContext: appContext)
        default:
            let appError = AppErr(error)
            switch appError {
            case .connection, .general:
                state = .error(appError.errorMessage)
            default:
                showAlert(error: error, message: "message_failed_load".localized)
            }
            tableNode.reloadData()
        }
    }
}

// MARK: - Action handlers
extension InboxViewController {
    private func handleInfoTap() {
        // todo - open compose screen with predefined human@flowcrypt.com recipient
        showToast("Email us at human@flowcrypt.com")
    }

    private func handleSearchTap() {
        Task {
            do {
                let viewController = try await SearchViewController(
                    appContext: appContext,
                    viewModel: viewModel,
                    apiClient: inboxDataApiClient,
                    isSearch: true
                )
                navigationController?.pushViewController(viewController, animated: false)
            } catch {
                showAlert(message: error.errorMessage)
            }
        }
    }

    @objc private func refresh() {
        logger.logInfo("Refresh")
        state = .refresh
        handleBeginFetching(nil)
    }

    private func btnComposeTap() {
        Task {
            do {
                TapTicFeedback.generate(.light)
                let composeVc = try await ComposeViewController(
                    appContext: appContext,
                    handleAction: { [weak self] action in
                        switch action {
                        case let .update(identifier), let .sent(identifier), let .delete(identifier):
                            self?.fetchUpdatedInboxItem(identifier: identifier)
                        }
                    }
                )
                navigationController?.pushViewController(composeVc, animated: true)
            } catch {
                showAlert(message: error.localizedDescription)
            }
        }
    }
}

// MARK: - Refreshable
extension InboxViewController: Refreshable {
    func startRefreshing() {
        refresh()
    }
}
