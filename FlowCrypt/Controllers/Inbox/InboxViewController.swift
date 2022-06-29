//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptCommon
import FlowCryptUI
import Foundation

@MainActor
class InboxViewController: ViewController {
    private lazy var logger = Logger.nested(Self.self)

    private let numberOfInboxItemsToLoad: Int

    private let appContext: AppContextWithUser
    private let decorator: InboxViewDecorator
    private let draftsListProvider: DraftsListProvider?
    private let messageOperationsProvider: MessageOperationsProvider
    private let refreshControl = UIRefreshControl()
    internal let tableNode: ASTableNode
    private lazy var composeButton = ComposeButtonNode { [weak self] in
        self?.btnComposeTap()
    }

    private let inboxDataProvider: InboxDataProvider
    private let viewModel: InboxViewModel
    internal var inboxInput: [InboxRenderable] = []
    internal var state: InboxViewController.State = .idle
    private var inboxTitle: String {
        viewModel.folderName.isEmpty ? "Inbox" : viewModel.folderName
    }
    private var shouldShowEmptyView: Bool {
        inboxInput.isNotEmpty && (viewModel.path == "SPAM" || viewModel.path == "TRASH")
    }

    var path: String { viewModel.path }

    // Search related varaibles
    internal var isSearch = false
    internal var searchedExpression = ""
    var shouldBeginFetch = true

    private var didLayoutSubviews = false

    init(
        appContext: AppContextWithUser,
        viewModel: InboxViewModel,
        numberOfInboxItemsToLoad: Int = 50,
        provider: InboxDataProvider,
        draftsListProvider: DraftsListProvider? = nil,
        decorator: InboxViewDecorator = InboxViewDecorator(),
        isSearch: Bool = false
    ) throws {
        self.appContext = appContext
        self.viewModel = viewModel
        self.numberOfInboxItemsToLoad = numberOfInboxItemsToLoad
        self.inboxDataProvider = provider

        let mailProvider = try appContext.getRequiredMailProvider()
        self.draftsListProvider = try draftsListProvider ?? mailProvider.draftsProvider
        self.messageOperationsProvider = try mailProvider.messageOperationsProvider
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

        if !self.isSearch {
            setupUI()
            setupNavigationBar()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
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
    private func setupUI() {
        title = inboxTitle
        navigationItem.setAccessibility(id: inboxTitle)

        setupTableNode()
        node.addSubnode(composeButton)
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
    }

    internal func setupTableNode() {
        tableNode.do {
            $0.delegate = self
            $0.dataSource = self
            $0.leadingScreensForBatching = 1
            $0.accessibilityIdentifier = "aid-inbox-list"
            $0.view.refreshControl = refreshControl
            node.addSubnode($0)
        }
    }

    private func setupNavigationBar() {
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
    }

    private func setupElements() {
        tableNode.frame = node.bounds

        if isSearch { return }

        let offset: CGFloat = 16
        let size = CGSize(width: 50, height: 50)

        composeButton.frame = CGRect(
            x: node.bounds.maxX - offset - size.width,
            y: node.bounds.maxY - offset - size.height - safeAreaWindowInsets.bottom,
            width: size.width,
            height: size.height
        )
        composeButton.cornerRadius = size.width / 2
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
        case .fetched(.byNextPage):
            return numberOfInboxItemsToLoad
        case .fetched(.byNumber(let totalNumberOfMessages)):
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
    private func fetchAndRenderEmails(_ batchContext: ASBatchContext?) {
        if let provider = draftsListProvider, viewModel.isDrafts {
            fetchAndRenderDrafts(batchContext, draftsProvider: provider)
        } else {
            fetchAndRenderEmailsOnly(batchContext)
        }
    }

    private func fetchAndRenderDrafts(_ batchContext: ASBatchContext?, draftsProvider: DraftsListProvider) {
        Task {
            do {
                let context = try await draftsProvider.fetchDrafts(
                    using: FetchMessageContext(
                        folderPath: viewModel.path,
                        count: numberOfInboxItemsToLoad,
                        pagination: currentMessagesListPagination()
                    )
                )
                let inboxContext = InboxContext(
                    data: context.messages.map(InboxRenderable.init),
                    pagination: context.pagination
                )
                handleEndFetching(with: inboxContext, context: batchContext)
            } catch {
                handle(error: error)
            }
        }
    }

    private func getSearchQuery() -> String? {
        guard searchedExpression.isNotEmpty else { return nil }

        guard !searchedExpression.hasPrefix("subject:") else { return searchedExpression }

        return "\(searchedExpression) OR subject:\(searchedExpression)"
    }

    internal func fetchAndRenderEmailsOnly(_ batchContext: ASBatchContext?) {
        Task {
            do {
                if isSearch {
                    state = .searching
                    await self.tableNode.reloadData()
                } else {
                    state = .fetching
                }

                let context = try await inboxDataProvider.fetchInboxItems(
                    using: FetchMessageContext(
                        folderPath: isSearch ? nil : viewModel.path, // pass nil in search screen to search for all folders
                        count: numberOfInboxItemsToLoad,
                        searchQuery: getSearchQuery(),
                        pagination: currentMessagesListPagination()
                    ), userEmail: appContext.user.email
                )
                state = .refresh
                handleEndFetching(with: context, context: batchContext)
            } catch {
                handle(error: error)
            }
        }
    }

    private func loadMore(_ batchContext: ASBatchContext?) {
        guard state.canLoadMore else { return }

        Task {
            do {
                let pagination = try currentMessagesListPagination(from: inboxInput.count)
                state = .fetching

                let context = try await inboxDataProvider.fetchInboxItems(
                    using: FetchMessageContext(
                        folderPath: viewModel.path,
                        count: messagesToLoad(),
                        pagination: pagination
                    ), userEmail: appContext.user.email
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
        context.beginBatchFetching()
        handleBeginFetching(context)
    }

    private func handleBeginFetching(_ context: ASBatchContext?) {
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
            if let context = context, context.isFetching() {
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
            if isSearch {
                state = .searchEmpty
            } else {
                state = .empty
            }
        } else {
            state = .fetched(input.pagination)
        }
        refreshControl.endRefreshing()
        // Disable should begin fetch event while table node is reloaded
        // This is to prevent inbox initially load 2 pages of emails
        // (willBeginBatchFetchWith called right after initial inbox load and it triggered another page load before)
        tableNode.reloadData(completion: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                self.shouldBeginFetch = true
            })
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
        case GmailServiceError.invalidGrant:
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
        #warning("ToDo")
        showToast("Email us at human@flowcrypt.com")
    }

    private func handleSearchTap() {
        do {
            let viewController = try SearchViewController(
                appContext: appContext,
                viewModel: viewModel,
                provider: self.inboxDataProvider,
                isSearch: true
            )
            navigationController?.pushViewController(viewController, animated: false)
        } catch {
            showAlert(message: error.errorMessage)
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
                let composeVc = try await ComposeViewController(appContext: appContext)
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

extension InboxViewController: ASTableDataSource, ASTableDelegate {
    func tableNode(_: ASTableNode, numberOfRowsInSection _: Int) -> Int {
        switch state {
        case .empty, .idle, .searchStart, .searching, .searchEmpty, .error:
            return 1
        case .fetched, .refresh:
            return shouldShowEmptyView ? inboxInput.count + 1 : inboxInput.count
        case .fetching:
            return inboxInput.count
        }
    }

    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        cellNode(for: indexPath, and: visibleSize(for: tableNode))
    }

    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        var rowNumber = indexPath.row
        if shouldShowEmptyView {
            rowNumber -= 1
        }
        guard let message = inboxInput[safe: rowNumber] else {
            return
        }
        tableNode.deselectRow(at: indexPath, animated: true)
        open(message: message, path: viewModel.path, appContext: appContext)
    }

    private func cellNode(for indexPath: IndexPath, and size: CGSize) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self = self else { return ASCellNode() }

            switch self.state {
            case .empty:
                return EmptyCellNode(
                    input: self.decorator.emptyStateNodeInput(
                        for: size,
                        title: self.inboxTitle,
                        imageName: self.viewModel.path.mailFolderIcon
                    )
                )
            case .searchStart:
                return TextCellNode(input: self.decorator.initialNodeInput(for: size, withSpinner: false))
            case .searchEmpty:
                return TextCellNode(input: self.decorator.searchEmptyStateNodeInput(for: size))
            case .searching:
                return TextCellNode.loading
            case .idle:
                let node = TextCellNode(input: self.decorator.initialNodeInput(for: size))
                node.accessibilityIdentifier = "aid-inbox-idle-node"
                return node
            case .fetched, .refresh:
                var rowNumber = indexPath.row
                if self.shouldShowEmptyView {
                    if indexPath.row == 0 {
                        return EmptyFolerCellNode(path: self.viewModel.path, emptyFolder: {
                            self.emptyInboxFolder()
                        })
                    }
                    rowNumber -= 1
                }
                guard let input = self.inboxInput[safe: rowNumber] else {
                    return TextCellNode.loading
                }
                return InboxCellNode(input: .init(input))
                    .then { $0.backgroundColor = .backgroundColor }
            case .fetching:
                guard let input = self.inboxInput[safe: indexPath.row] else {
                    return TextCellNode.loading
                }
                return InboxCellNode(input: .init(input))
            case let .error(message):
                return TextCellNode(
                    input: TextCellNode.Input(
                        backgroundColor: .backgroundColor,
                        title: message,
                        withSpinner: false,
                        size: size
                    )
                )
            }
        }
    }

    private func emptyInboxFolder() {
        Task {
            do {
                self.showSpinner()
                try await self.messageOperationsProvider.emptyFolder(path: viewModel.path)
                self.state = .empty
                self.inboxInput = []
                await tableNode.reloadData()
                self.hideSpinner()
            } catch {
                self.showAlert(message: error.errorMessage)
            }
        }
    }
}

// MARK: - MsgListViewController
extension InboxViewController: MsgListViewController {
    func getUpdatedIndex(for message: InboxRenderable) -> Int? {
        let index = inboxInput.firstIndex(where: {
            $0.title == message.title && $0.subtitle == message.subtitle && $0.wrappedType == message.wrappedType
        })
        logger.logInfo("Try to update message at \(String(describing: index))")
        return index
    }

    func updateMessage(isRead: Bool, at index: Int) {
        guard inboxInput.count > index else { return }

        logger.logInfo("Mark as read \(isRead) at \(index)")
        inboxInput[index].isRead = isRead

        // Mark wrapped message/thread(all mails in thread) as read/unread
        if var wrappedThread = inboxInput[index].wrappedThread {
            for i in 0 ..< wrappedThread.messages.count {
                wrappedThread.messages[i].markAsRead(isRead)
            }
            inboxInput[index].wrappedType = .thread(wrappedThread)
        } else if var wrappedMessage = inboxInput[index].wrappedMessage {
            wrappedMessage.markAsRead(isRead)
            inboxInput[index].wrappedType = .message(wrappedMessage)
        }

        let animationDuration = 0.3
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) { [weak self] in
            self?.tableNode.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
        }
    }

    func updateMessage(labelsToAdd: [MessageLabel], labelsToRemove: [MessageLabel], at index: Int) {
        guard inboxInput.count > index else { return }

        inboxInput[index].updateMessage(labelsToAdd: labelsToAdd, labelsToRemove: labelsToRemove)

        let animationDuration = 0.3
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) { [weak self] in
            self?.tableNode.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
        }
    }

    func removeMessage(at index: Int) {
        guard inboxInput[safe: index] != nil else { return }

        logger.logInfo("Try to remove at \(index)")
        inboxInput.remove(at: index)

        guard inboxInput.isNotEmpty else {
            state = .empty
            tableNode.reloadData()
            return
        }
        switch state {
        case .fetched(.byNumber(let total)):
            let newTotalNumber = (total ?? 0) - 1
            if newTotalNumber == 0 {
                state = .empty
                tableNode.reloadData()
            } else {
                state = .fetched(.byNumber(total: newTotalNumber))
                do {
                    try ObjcException.catch {
                        self.tableNode.deleteRows(at: [IndexPath(row: index, section: 0)], with: .left)
                    }
                } catch {
                    showAlert(message: "Failed to remove message at \(index) in fetched state: \(error)")
                }
            }
        default:
            do {
                try ObjcException.catch {
                    self.tableNode.deleteRows(at: [IndexPath(row: index, section: 0)], with: .left)
                }
            } catch {
                showAlert(message: "Failed to remove message at \(index) in \(state): \(error)")
            }
        }
    }
}
