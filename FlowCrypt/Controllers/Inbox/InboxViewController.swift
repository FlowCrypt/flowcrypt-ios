//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptCommon
import FlowCryptUI
import Promises

/**
 * View controller which shows message list of selected folder or inbox
 * - Initial view controller of the *main flow* when user is already signed in
 * - User can be redirected here via selecting folder from menu *MyMenuViewController*
 */
final class InboxViewController: ASDKViewController<ASDisplayNode> {
    private enum Constants {
        static let numberOfMessagesToLoad = 50
    }

    enum State {
        /// Just loaded scene
        case idle
        /// Fetched without any messages
        case empty
        /// Performing fetching of new messages
        case fetching
        /// Performing refreshing
        case refresh
        /// Fetched messages
        case fetched(_ pagination: MessagesListPagination)
        /// error state with description message
        case error(_ message: String)

        var canLoadMore: Bool {
            switch self {
            case let .fetched(.byNextPage(token)):
                return token != nil
            case let .fetched(.byNumber(total)):
                return (total ?? 0) > 0
            default:
                return false
            }
        }

        var token: String? {
            switch self {
            case let .fetched(.byNextPage(token)):
                return token
            default:
                return nil
            }
        }
    }

    private var state: State = .idle

    private let messageProvider: MessagesListProvider
    private let decorator: InboxViewDecorator
    private let enterpriseServerApi: EnterpriseServerApiType
    private let refreshControl = UIRefreshControl()
    private let tableNode: ASTableNode
    private lazy var composeButton = ComposeButtonNode { [weak self] in
        self?.btnComposeTap()
    }

    private let viewModel: InboxViewModel
    private var messages: [Message] = []

    var path: String { viewModel.path }

    init(
        _ viewModel: InboxViewModel,
        messageProvider: MessagesListProvider = MailProvider.shared.messageListProvider,
        decorator: InboxViewDecorator = InboxViewDecorator(),
        enterpriseServerApi: EnterpriseServerApiType = EnterpriseServerApi()
    ) {
        self.viewModel = viewModel
        self.messageProvider = messageProvider
        self.decorator = decorator
        self.enterpriseServerApi = enterpriseServerApi
        tableNode = TableNode()

        super.init(node: ASDisplayNode())

        tableNode.delegate = self
        tableNode.dataSource = self
        tableNode.leadingScreensForBatching = 1
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupNavigationBar()
        fetchAndRenderEmails(nil)
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

        node.addSubnode(tableNode)
        node.addSubnode(composeButton)

        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        tableNode.view.refreshControl = refreshControl
    }

    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = NavigationBarItemsView(
            with: [
                NavigationBarItemsView.Input(image: UIImage(named: "help_icn"), action: (self, #selector(handleInfoTap))),
                NavigationBarItemsView.Input(image: UIImage(named: "search_icn"), action: (self, #selector(handleSearchTap)))
            ]
        )
    }

    private var inboxTitle: String {
        viewModel.folderName.isEmpty ? "Inbox" : viewModel.folderName
    }
}

// MARK: - Functionality
extension InboxViewController {
    private func fetchAndRenderEmails(_ batchContext: ASBatchContext?) {
        messageProvider.fetchMessages(
            using: FetchMessageContext(
                folderPath: viewModel.path,
                count: Constants.numberOfMessagesToLoad,
                pagination: currentMessagesListPagination()
            )
        )
        .then { [weak self] context in
            self?.handleEndFetching(with: context, context: batchContext)
        }
        .catch(on: .main) { [weak self] error in
            self?.handle(error: error)
        }
    }

    private func loadMore(_ batchContext: ASBatchContext?) {
        guard state.canLoadMore else { return }

        let pagination = currentMessagesListPagination(from: messages.count)
        state = .fetching

        messageProvider.fetchMessages(
            using: FetchMessageContext(
                folderPath: viewModel.path,
                count: messagesToLoad(),
                pagination: pagination
            )
        )
        .then { [weak self] context in
            self?.state = .fetched(context.pagination)
            self?.handleEndFetching(with: context, context: batchContext)
        }
        .catch(on: .main) { [weak self] error in
            self?.handle(error: error)
        }
    }

    private func handleEndFetching(with messageContext: MessageContext, context: ASBatchContext?) {
        context?.completeBatchFetching(true)

        switch state {
        case .idle, .refresh:
            handleNew(messageContext)
        case .fetched:
            handleFetched(messageContext)
        default: break
        }
    }

    private func handleNew(_ messageContext: MessageContext) {
        if messageContext.messages.isEmpty {
            state = .empty
        } else {
            messages = messageContext.messages
                .sorted(by: { $0.date > $1.date })
            state = .fetched(messageContext.pagination)
        }
        DispatchQueue.main.async {
            self.refreshControl.endRefreshing()
            self.tableNode.reloadData()
        }
    }

    private func handleFetched(_ messageContext: MessageContext) {
        let count = messages.count - 1

        // insert new messages
        let indexesToInsert = messageContext.messages
            .enumerated()
            .map { index, _ -> Int in
                let indexInTableView = index + count
                return indexInTableView
            }
            .map { IndexPath(row: $0, section: 0) }

        messages.append(contentsOf: messageContext.messages)
        state = .fetched(messageContext.pagination)

        DispatchQueue.main.async {
            self.refreshControl.endRefreshing()
            self.tableNode.insertRows(at: indexesToInsert, with: .none)
        }
    }

    private func handle(error: Error) {
        refreshControl.endRefreshing()
        let appError = AppErr(error)

        switch appError {
        case .connection:
            state = .error(appError.userMessage)
            tableNode.reloadData()
        default:
            showAlert(error: error, message: "message_failed_load".localized)
        }
    }
}

// MARK: - Action handlers
extension InboxViewController {
    @objc private func handleInfoTap() {
        #warning("ToDo")
        showToast("Email us at human@flowcrypt.com")
    }

    @objc private func handleSearchTap() {
        let viewController = SearchViewController(folderPath: viewModel.path)
        navigationController?.pushViewController(viewController, animated: false)
    }

    @objc private func refresh() {
        state = .refresh
        handleBeginFetching(nil)
    }

    private func btnComposeTap() {
        guard let email = DataService.shared.email else {
            return
        }
        TapTicFeedback.generate(.light)
        let composeVc = ComposeViewController(email: email)
        navigationController?.pushViewController(composeVc, animated: true)
    }
}

// MARK: - MsgListViewConroller
extension InboxViewController: MsgListViewConroller {
    func msgListGetIndex(message: Message) -> Int? {
        messages.firstIndex(of: message)
    }

    func msgListRenderAsRemoved(message _: Message, at index: Int) {
        guard messages[safe: index] != nil else { return }
        messages.remove(at: index)

        guard messages.isNotEmpty else {
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

    func msgListRenderAsRead(message: Message, at index: Int) {
        messages[index] = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let self = self else { return }
            self.tableNode.reloadRows(at: [IndexPath(row: index, section: 0)], with: .fade)
        }
    }
}

// MARK: - ASTableDataSource, ASTableDelegate
extension InboxViewController: ASTableDataSource, ASTableDelegate {
    func tableNode(_: ASTableNode, numberOfRowsInSection _: Int) -> Int {
        switch state {
        case .empty, .idle, .error:
            return 1
        case .fetching, .fetched, .refresh:
            return messages.count
        }
    }

    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        cellNode(for: indexPath, and: visibleSize(for: tableNode))
    }

    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        tableNode.deselectRow(at: indexPath, animated: true)
        guard let message = messages[safe: indexPath.row] else { return }

        msgListOpenMsgElseShowToast(with: message, path: viewModel.path)
    }
}

// MARK: - Cell Nodes
extension InboxViewController {
    private func cellNode(for indexPath: IndexPath, and size: CGSize) -> ASCellNodeBlock {
        { [weak self] in
            guard let self = self else { return ASCellNode() }

            switch self.state {
            case .empty:
                return TextCellNode(input: self.decorator.emptyStateNodeInput(for: size, title: self.inboxTitle))
            case .idle:
                return TextCellNode(input: self.decorator.initialNodeInput(for: size))
            case .fetched, .refresh:
                return InboxCellNode(message: InboxCellNode.Input(self.messages[indexPath.row]))
                    .then { $0.backgroundColor = .backgroundColor }
            case .fetching:
                guard let message = self.messages[safe: indexPath.row] else {
                    return TextCellNode(
                        input: .loading(with: CGSize(width: 44, height: 44))
                    )
                }
                return InboxCellNode(message: InboxCellNode.Input(message))
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

// MARK: - Pagination
extension InboxViewController {
    func shouldBatchFetch(for _: ASTableNode) -> Bool {
        switch state {
        case .idle:
            return false
        case .fetched(.byNumber(let total)):
            return messages.count < total ?? 0
        case .fetched(.byNextPage(let token)):
            return token != nil
        case .error, .refresh, .fetching, .empty:
            return false
        }
    }

    func tableNode(_: ASTableNode, willBeginBatchFetchWith context: ASBatchContext) {
        context.beginBatchFetching()
        handleBeginFetching(context)
    }

    private func handleBeginFetching(_ context: ASBatchContext?) {
        switch state {
        case .idle:
            break
        case let .fetched(.byNumber(total)):
            if messages.count != total {
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

// MARK: - Pagination helpers
extension InboxViewController {
    private func currentMessagesListPagination(from number: Int? = nil) -> MessagesListPagination {
        MailProvider.shared.currentMessagesListPagination(from: number, token: state.token)
    }

    private func messagesToLoad() -> Int {
        switch state {
        case .fetched(.byNextPage):
            return Constants.numberOfMessagesToLoad
        case .fetched(.byNumber(let totalNumberOfMessages)):
            guard let total = totalNumberOfMessages else {
                return Constants.numberOfMessagesToLoad
            }
            let from = messages.count
            return min(Constants.numberOfMessagesToLoad, total - from)
        default:
            return Constants.numberOfMessagesToLoad
        }
    }
}

extension InboxViewController: Refreshable {

     func startRefreshing() {
         refresh()
     }
 }
