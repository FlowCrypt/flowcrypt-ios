//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptCommon
import FlowCryptUI
import Promises

class InboxViewController:
    ASDKViewController<ASDisplayNode>,
    ASTableDataSource,
    ASTableDelegate,
    Refreshable {

    private let numberOfMessagesToLoad: Int
    private let provider: InboxDataProvider
    private let decorator: InboxViewDecorator
    private let refreshControl = UIRefreshControl()
    private let tableNode: ASTableNode
    private lazy var composeButton = ComposeButtonNode { [weak self] in
        self?.btnComposeTap()
    }

    private let viewModel: InboxViewModel
    private var inboxData: [InboxRenderable] = []
    private var state: InboxViewController.State = .idle
    private var inboxTitle: String {
        viewModel.folderName.isEmpty ? "Inbox" : viewModel.folderName
    }

    var path: String { viewModel.path }

    init(
        _ viewModel: InboxViewModel,
        numberOfMessagesToLoad: Int,
        provider: InboxDataProvider,
        decorator: InboxViewDecorator = InboxViewDecorator()
    ) {
        self.viewModel = viewModel
        self.numberOfMessagesToLoad = numberOfMessagesToLoad
        self.provider = provider
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

    // MARK: - UI
    private func setupUI() {
        title = inboxTitle

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
                NavigationBarItemsView.Input(image: UIImage(named: "help_icn"), action: (self, #selector(handleInfoTap))),
                NavigationBarItemsView.Input(image: UIImage(named: "search_icn"), action: (self, #selector(handleSearchTap)))
            ]
        )
    }
    // MARK: - Helpers
    private func currentMessagesListPagination(from number: Int? = nil) -> MessagesListPagination {
        MailProvider.shared.currentMessagesListPagination(from: number, token: state.token)
    }

    private func messagesToLoad() -> Int {
        switch state {
        case .fetched(.byNextPage):
            return numberOfMessagesToLoad
        case .fetched(.byNumber(let totalNumberOfMessages)):
            guard let total = totalNumberOfMessages else {
                return numberOfMessagesToLoad
            }
            let from = inboxData.count
            return min(numberOfMessagesToLoad, total - from)
        default:
            return numberOfMessagesToLoad
        }
    }

    // MARK: - Functionality
    private func fetchAndRenderEmails(_ batchContext: ASBatchContext?) {
        provider.fetchMessages(
            using: FetchMessageContext(
                folderPath: viewModel.path,
                count: numberOfMessagesToLoad,
                pagination: currentMessagesListPagination()
            )
        )
            .then(on: .main) { [weak self] value in
                self?.handleEndFetching(with: value, context: batchContext)
            }
            .catch(on: .main) { [weak self] error in
                self?.handle(error: error)
            }
    }

    private func loadMore(_ batchContext: ASBatchContext?) {
        guard state.canLoadMore else { return }

        let pagination = currentMessagesListPagination(from: inboxData.count)
        state = .fetching

        provider.fetchMessages(
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

    func shouldBatchFetch(for _: ASTableNode) -> Bool {
        switch state {
        case .idle:
            return false
        case .fetched(.byNumber(let total)):
            return inboxData.count < total ?? 0
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
            if inboxData.count != total {
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

    // MARK: - Functionality Input
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
            inboxData = input.data
                // .sorted()

            // TODO: - ANTON
            // .sorted(by: { $0.date > $1.date })
            state = .fetched(input.pagination)
        }
        refreshControl.endRefreshing()
        tableNode.reloadData()
    }

    private func handleFetched(_ input: InboxContext) {
        let count = inboxData.count - 1

        // insert new messages
        let indexesToInsert = input.data
            .enumerated()
            .map { index, _ -> Int in
                let indexInTableView = index + count
                return indexInTableView
            }
            .map { IndexPath(row: $0, section: 0) }

        inboxData.append(contentsOf: input.data)
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
        case .connection:
            state = .error(appError.userMessage)
        case .general(let errorMessage):
            state = .error(errorMessage)
        default:
            showAlert(error: error, message: "message_failed_load".localized)
        }
        tableNode.reloadData()
    }

    // MARK: - Action handlers
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

    // MARK: - Refreshable
    func startRefreshing() {
        refresh()
    }

    // MARK: - ASTableDataSource, ASTableDelegate
    func tableNode(_: ASTableNode, numberOfRowsInSection _: Int) -> Int {
        switch state {
        case .empty, .idle, .error:
            return 1
        case .fetching, .fetched, .refresh:
            return inboxData.count
        }
    }

    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        cellNode(for: indexPath, and: visibleSize(for: tableNode))
    }

    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        tableNode.deselectRow(at: indexPath, animated: true)
        guard let message = inboxData[safe: indexPath.row] else { return }

        // TODO: - ANTON
//        msgListOpenMsgElseShowToast(with: message, path: viewModel.path)
    }

    // MARK: - Cell Nodes
    private func cellNode(for indexPath: IndexPath, and size: CGSize) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self = self else { return ASCellNode() }

            switch self.state {
            case .empty:
                return TextCellNode(input: self.decorator.emptyStateNodeInput(for: size, title: self.inboxTitle))
            case .idle:
                return TextCellNode(input: self.decorator.initialNodeInput(for: size))
            case .fetched, .refresh:
                return InboxCellNode(message: .init((self.inboxData[indexPath.row])))
                    .then { $0.backgroundColor = .backgroundColor }
            case .fetching:
                guard let message = self.inboxData[safe: indexPath.row] else {
                    return TextCellNode.loading
                }
                return InboxCellNode(message: .init(message))
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

//
//// MARK: - MsgListViewController
//extension InboxViewController: MsgListViewController {
//    func msgListGetIndex(message: Message) -> Int? {
////        messages.firstIndex(of: message)
//    }
//
//    func msgListRenderAsRemoved(message _: Message, at index: Int) {
////        guard messages[safe: index] != nil else { return }
////        messages.remove(at: index)
////
////        guard messages.isNotEmpty else {
////            state = .empty
////            tableNode.reloadData()
////            return
////        }
////        switch state {
////        case .fetched(.byNumber(let total)):
////            let newTotalNumber = (total ?? 0) - 1
////            if newTotalNumber == 0 {
////                state = .empty
////                tableNode.reloadData()
////            } else {
////                state = .fetched(.byNumber(total: newTotalNumber))
////                tableNode.deleteRows(at: [IndexPath(row: index, section: 0)], with: .left)
////            }
////        default:
////            tableNode.deleteRows(at: [IndexPath(row: index, section: 0)], with: .left)
////        }
//    }
//
//    func msgListRenderAsRead(message: Message, at index: Int) {
////        messages[index] = message
////        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
////            guard let self = self else { return }
////            self.tableNode.reloadRows(at: [IndexPath(row: index, section: 0)], with: .fade)
////        }
//    }
//}
