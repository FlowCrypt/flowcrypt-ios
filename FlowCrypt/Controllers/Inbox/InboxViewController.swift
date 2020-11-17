//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptCommon
import FlowCryptUI
import Promises

final class InboxViewController: ASDKViewController<ASDisplayNode> {
    private enum Constants {
        static let numberOfMessagesToLoad = 20
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
        /// Fetched messages where
        case fetched(_ totalNumberOfMessages: Int)
        /// error state with description message
        case error(_ message: String)

        var total: Int? {
            switch self {
            case let .fetched(totalNumberOfMessages): return totalNumberOfMessages
            default: return nil
            }
        }
    }

    private var state: State = .idle

    private let messageProvider: MessagesListProvider
    private let viewModel: InboxViewModel
    private var messages: [MCOIMAPMessage] = []
    private let tableNode: ASTableNode

    private lazy var composeButton = ComposeButtonNode { [weak self] in
        self?.btnComposeTap()
    }

    private let refreshControl = UIRefreshControl()

    init(
        _ viewModel: InboxViewModel = .empty,
        messageProvider: MessagesListProvider = GlobalServices.shared.messageProvider
    ) {
        self.viewModel = viewModel
        self.messageProvider = messageProvider
        tableNode = TableNode()

        super.init(node: ASDisplayNode())

        tableNode.delegate = self
        tableNode.dataSource = self
        tableNode.leadingScreensForBatching = 1
    }

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
        guard #available(iOS 13.0, *) else { return }
        tableNode.reloadData()
    }
}

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

extension InboxViewController {
    // TODO: - ANTON - MessagesListPagination
    private func currentMessagesListPagination(from number: Int? = nil, token: String? = nil) -> MessagesListPagination {
        return MessagesListPagination.byNumber(from: number ?? 0)
        switch GlobalServices.shared.authType {
        case .password: return MessagesListPagination.byNumber(from: number ?? 0)
        case .gmail: return .byNextPage(token: token)
        }
    }
}

extension InboxViewController {
    private func fetchAndRenderEmails(_ batchContext: ASBatchContext?) {
        messageProvider
            .fetchMessages(
                for: viewModel.path,
                count: Constants.numberOfMessagesToLoad,
                using: currentMessagesListPagination()
            )
            .then { [weak self] context in
                self?.handleEndFetching(with: context, context: batchContext)
            }
            .catch(on: .main) { [weak self] error in
                self?.handle(error: error)
            }
    }

    private func loadMore(_ batchContext: ASBatchContext?) {
        guard let totalNumberOfMessages = state.total else { return }

        state = .fetching
        let from = messages.count
        let diff = min(Constants.numberOfMessagesToLoad, totalNumberOfMessages - from)
        messageProvider
            .fetchMessages(
                for: viewModel.path,
                count: diff,
                using: currentMessagesListPagination(from: from)
            )
            .then { [weak self] context in
                self?.state = .fetched(context.totalMessages)
                self?.handleEndFetching(with: context, context: batchContext)
            }
            .catch(on: .main) { [weak self] error in
                self?.handle(error: error)
            }
    }

    private func handleEndFetching(with messageContext: MessageContext, context: ASBatchContext?) {
        context?.completeBatchFetching(true)

        switch state {
        case .idle, .refresh: handleNew(messageContext)
        case .fetched: handleFetched(messageContext)
        default: break
        }
    }

    private func handleNew(_ messageContext: MessageContext) {
        if messageContext.messages.isEmpty {
            state = .empty
        } else {
            messages = messageContext.messages
                .sorted(by: { $0.header.date > $1.header.date })
            state = .fetched(messageContext.totalMessages)
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
            .map { (index, _) -> Int in
                let indexInTableView = index + count
                return indexInTableView
            }
            .map { IndexPath(row: $0, section: 0) }

        messages.append(contentsOf: messageContext.messages)
        state = .fetched(messageContext.totalMessages)

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
        TapTicFeedback.generate(.light)
        let composeVc = ComposeViewController()
        navigationController?.pushViewController(composeVc, animated: true)
    }
}

extension InboxViewController: MsgListViewConroller {
    func msgListGetIndex(message: MCOIMAPMessage) -> Int? {
        return messages.firstIndex(of: message)
    }

    func msgListRenderAsRemoved(message _: MCOIMAPMessage, at index: Int) {
        guard messages[safe: index] != nil else { return }
        messages.remove(at: index)
        if messages.isEmpty {
            state = .empty
            tableNode.reloadData()
        } else {
            let total = state.total ?? 0
            let newTotalCount = total - 1
            state = .fetched(newTotalCount)
            tableNode.deleteRows(at: [IndexPath(row: index, section: 0)], with: .left)
        }
    }

    func msgListRenderAsRead(message: MCOIMAPMessage, at index: Int) {
        messages[index] = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let self = self else { return }
            self.tableNode.reloadRows(at: [IndexPath(row: index, section: 0)], with: .fade)
        }
    }
}

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
        let height = tableNode.frame.size.height
            - (navigationController?.navigationBar.frame.size.height ?? 0.0)
            - safeAreaWindowInsets.top
            - safeAreaWindowInsets.bottom

        let size = CGSize(
            width: tableNode.frame.size.width,
            height: max(height, 0)
        )

        return cellNode(for: indexPath, and: size)
    }

    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        tableNode.deselectRow(at: indexPath, animated: true)
        guard let message = messages[safe: indexPath.row] else { return }

        msgListOpenMsgElseShowToast(with: message, path: viewModel.path)
    }
}

extension InboxViewController {
    private func cellNode(for indexPath: IndexPath, and size: CGSize) -> ASCellNodeBlock { { [weak self] in
        guard let self = self else { return ASCellNode() }

        switch self.state {
        case .empty:
            return TextCellNode(
                input: TextCellNode.Input(
                    backgroundColor: .backgroundColor,
                    title: "\(self.inboxTitle) is empty",
                    withSpinner: false,
                    size: size
                )
            )
        case .idle:
            return TextCellNode(
                input: TextCellNode.Input(
                    backgroundColor: .backgroundColor,
                    title: "",
                    withSpinner: true,
                    size: size
                )
            )
        case .fetched, .refresh:
            return InboxCellNode(message: InboxCellNode.Input(self.messages[indexPath.row]))
                .then { $0.backgroundColor = .backgroundColor }
        case .fetching:
            guard let message = self.messages[safe: indexPath.row] else {
                return TextCellNode(
                    input: TextCellNode.Input(
                        backgroundColor: .backgroundColor,
                        title: "Loading ...",
                        withSpinner: true,
                        size: CGSize(width: 44, height: 44)
                    )
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

extension InboxViewController {
    func shouldBatchFetch(for _: ASTableNode) -> Bool {
        switch state {
        case .idle: return false
        case .fetched: return messages.count < state.total ?? 0
        case .error, .refresh, .fetching, .empty: return false
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
        case let .fetched(total):
            if messages.count != total {
                loadMore(context)
            }
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
