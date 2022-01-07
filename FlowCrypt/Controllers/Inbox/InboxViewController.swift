//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptCommon
import FlowCryptUI
import Foundation

@MainActor
final class InboxViewController: ASDKViewController<ASDisplayNode> {
    private lazy var logger = Logger.nested(Self.self)

    private let numberOfInboxItemsToLoad: Int

    private let appContext: AppContext
    private let user: User
    private let service: ServiceActor
    private let decorator: InboxViewDecorator
    private let draftsListProvider: DraftsListProvider?
    private let refreshControl = UIRefreshControl()
    private let tableNode: ASTableNode
    private lazy var composeButton = ComposeButtonNode { [weak self] in
        self?.btnComposeTap()
    }

    private let viewModel: InboxViewModel
    private var inboxInput: [InboxRenderable] = []
    private var state: InboxViewController.State = .idle
    private var inboxTitle: String {
        viewModel.folderName.isEmpty ? "Inbox" : viewModel.folderName
    }

    var path: String { viewModel.path }

    init(
        appContext: AppContext,
        _ viewModel: InboxViewModel,
        numberOfInboxItemsToLoad: Int = 50,
        provider: InboxDataProvider,
        draftsListProvider: DraftsListProvider? = nil,
        decorator: InboxViewDecorator = InboxViewDecorator()
    ) {
        guard let user = appContext.dataService.currentUser else {
            fatalError("missing current user") // todo - DI user
        }
        self.user = user
        self.appContext = appContext
        self.viewModel = viewModel
        self.numberOfInboxItemsToLoad = numberOfInboxItemsToLoad

        self.service = ServiceActor(inboxDataProvider: provider)
        self.draftsListProvider = draftsListProvider ?? appContext.getRequiredMailProvider().draftsProvider
        self.decorator = decorator
        self.tableNode = TableNode()

        super.init(node: ASDisplayNode())
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupNavigationBar()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let offset: CGFloat = 16
        let size = CGSize(width: 50, height: 50)

        composeButton.frame = CGRect(
            x: node.bounds.maxX - offset - size.width,
            y: node.bounds.maxY - offset - size.height - safeAreaWindowInsets.bottom,
            width: size.width,
            height: size.height
        )
        composeButton.cornerRadius = size.width / 2
        tableNode.frame = node.bounds
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        tableNode.reloadData()
    }
}

// MARK: - UI
extension InboxViewController {
    private func setupUI() {
        title = inboxTitle
        navigationItem.setAccessibility(id: inboxTitle)

        tableNode.do {
            $0.delegate = self
            $0.dataSource = self
            $0.leadingScreensForBatching = 1
            $0.view.refreshControl = refreshControl
            node.addSubnode($0)
        }

        node.addSubnode(composeButton)
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
    }

    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = NavigationBarItemsView(
            with: [
                NavigationBarItemsView.Input(image: UIImage(named: "help_icn")) { [weak self] in self?.handleInfoTap() },
                NavigationBarItemsView.Input(image: UIImage(named: "search_icn")) { [weak self] in self?.handleSearchTap() }
            ]
        )
    }
}

// MARK: - Helpers
extension InboxViewController {
    private func currentMessagesListPagination(from number: Int? = nil) -> MessagesListPagination {
        appContext
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
                    data: context.messages.map { InboxRenderable(message: $0) },
                    pagination: context.pagination
                )
                handleEndFetching(with: inboxContext, context: batchContext)
            } catch {
                handle(error: error)
            }
        }
    }

    private func fetchAndRenderEmailsOnly(_ batchContext: ASBatchContext?) {
        Task {
            do {
                let context = try await service.fetchInboxItems(
                    using: FetchMessageContext(
                        folderPath: viewModel.path,
                        count: numberOfInboxItemsToLoad,
                        pagination: currentMessagesListPagination()
                    ), userEmail: user.email
                )
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
                let pagination = currentMessagesListPagination(from: inboxInput.count)
                state = .fetching

                let context = try await service.fetchInboxItems(
                    using: FetchMessageContext(
                        folderPath: viewModel.path,
                        count: messagesToLoad(),
                        pagination: pagination
                    ), userEmail: user.email
                )
                state = .fetched(context.pagination)
                handleEndFetching(with: context, context: batchContext)
            } catch {
                handle(error: error)
            }
        }
    }

    func tableNode(_: ASTableNode, willBeginBatchFetchWith context: ASBatchContext) {
        context.beginBatchFetching()
        handleBeginFetching(context)
    }

    private func handleBeginFetching(_ context: ASBatchContext?) {
        switch state {
        case .idle:
            fetchAndRenderEmails(context)
        case let .fetched(.byNumber(total)):
            if inboxInput.count != total {
                loadMore(context)
            }
        case let .fetched(.byNextPage(token)):
            guard token != nil else { return }
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
        case .error:
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
        if input.data.isEmpty {
            state = .empty
        } else {
            inboxInput = input.data
            state = .fetched(input.pagination)
        }
        refreshControl.endRefreshing()
        tableNode.reloadData()
    }

    private func handleFetched(_ input: InboxContext) {
        let count = inboxInput.count - 1

        // insert new messages
        let indexesToInsert = input.data
            .enumerated()
            .map { index, _ -> Int in
                let indexInTableView = index + count
                return indexInTableView
            }
            .map { IndexPath(row: $0, section: 0) }

        inboxInput.append(contentsOf: input.data)
        state = .fetched(input.pagination)

        DispatchQueue.main.async {
            self.refreshControl.endRefreshing()
            self.tableNode.insertRows(at: indexesToInsert, with: .none)
        }
    }

    private func handle(error: Error) {
        refreshControl.endRefreshing()
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

// MARK: - Action handlers
extension InboxViewController {
    private func handleInfoTap() {
        #warning("ToDo")
        showToast("Email us at human@flowcrypt.com")
    }

    private func handleSearchTap() {
        let viewController = SearchViewController(appContext: appContext, folderPath: viewModel.path)
        navigationController?.pushViewController(viewController, animated: false)
    }

    @objc private func refresh() {
        logger.logInfo("Refresh")
        state = .refresh
        handleBeginFetching(nil)
    }

    private func btnComposeTap() {
        TapTicFeedback.generate(.light)
        let composeVc = ComposeViewController(appContext: appContext)
        navigationController?.pushViewController(composeVc, animated: true)
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
        case .empty, .idle, .error:
            return 1
        case .fetching, .fetched, .refresh:
            return inboxInput.count
        }
    }

    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        cellNode(for: indexPath, and: visibleSize(for: tableNode))
    }

    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        tableNode.deselectRow(at: indexPath, animated: true)
        open(with: inboxInput[indexPath.row], path: viewModel.path, appContext: appContext)
    }

    // MARK: Cell Nodes
    private func cellNode(for indexPath: IndexPath, and size: CGSize) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self = self else { return ASCellNode() }

            switch self.state {
            case .empty:
                return TextCellNode(input: self.decorator.emptyStateNodeInput(for: size, title: self.inboxTitle))
            case .idle:
                return TextCellNode(input: self.decorator.initialNodeInput(for: size))
            case .fetched, .refresh:
                return InboxCellNode(input: .init((self.inboxInput[indexPath.row])))
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
}

// MARK: - MsgListViewController
extension InboxViewController: MsgListViewController {
    func getUpdatedIndex(for message: InboxRenderable) -> Int? {
        let index = inboxInput.firstIndex(where: {
            $0.title == message.title
            && $0.subtitle == message.subtitle
        })
        logger.logInfo("Try to update message at \(String(describing: index))")
        return index
    }

    func updateMessage(isRead: Bool, at index: Int) {
        guard var input = inboxInput[safe: index] else {
            return
        }
        logger.logInfo("Mark as read \(isRead) at \(index)")
        input.isRead = isRead
        inboxInput[index] = input

        if inboxInput[index].wrappedMessage == nil {
            refresh()
        } else {
            let animationDuration = 0.3
            DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) { [weak self] in
                self?.tableNode.reloadRows(at: [IndexPath(row: index, section: 0)], with: .fade)
            }
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
                tableNode.deleteRows(at: [IndexPath(row: index, section: 0)], with: .left)
            }
        default:
            tableNode.deleteRows(at: [IndexPath(row: index, section: 0)], with: .left)
        }
    }
}

// TODO temporary solution for background execution problem
private actor ServiceActor {
    private let inboxDataProvider: InboxDataProvider

    init(inboxDataProvider: InboxDataProvider) {
        self.inboxDataProvider = inboxDataProvider
    }

    func fetchInboxItems(using context: FetchMessageContext, userEmail: String) async throws -> InboxContext {
        return try await inboxDataProvider.fetchInboxItems(using: context, userEmail: userEmail)
    }
}
