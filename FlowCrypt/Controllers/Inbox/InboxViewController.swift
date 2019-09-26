//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit
import Promises
import RxSwift
import AsyncDisplayKit

final class InboxViewController: ASViewController<ASDisplayNode> {
    private enum Constants {
        static let numberOfMessagesToLoad = 20
        static let messageSizeLimit: Int = 5_000_000
    }

    enum State {
        case idle, empty, tailFetching, fetched(_ totalNumberOfMessages: Int)

        var total: Int? {
            switch self {
            case let .fetched(totalNumberOfMessages): return totalNumberOfMessages
            default: return nil
            }
        }
    }

    enum Action {
        case beginBatchFetch
        case endBatchFetch(messageContext: MessageContext)
    }

    private var state: State = .idle

    private let messageProvider: MessageProvider = Imap.instance
    private var messages: [MCOIMAPMessage] = []
    private var viewModel: InboxViewModel


    private var tableNode: ASTableNode
    private lazy var composeButton = ComposeButtonNode() { [weak self] in
        self?.btnComposeTap()
    }
    private let refreshControl = UIRefreshControl()

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    init(_ viewModel: InboxViewModel = .empty) {
        self.viewModel = viewModel
        self.tableNode = ASTableNode(style: .plain)
        super.init(node: ASDisplayNode())

        tableNode.delegate = self
        tableNode.dataSource = self
        tableNode.leadingScreensForBatching = 1
    }

    required init?(coder aDecoder: NSCoder) {
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
            y: node.bounds.maxY - offset - size.height,
            width: size.width,
            height: size.height
        )
        composeButton.cornerRadius = size.width / 2
        tableNode.frame = node.bounds
    }
}

extension InboxViewController {
    private func setupUI() {
        title = viewModel.folderName.isEmpty
            ? "Inbox"
            : viewModel.folderName

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
}

extension InboxViewController {
    private func fetchAndRenderEmails(_ batchContext: ASBatchContext?) {
        messageProvider
            .fetchMessages(for: viewModel.path, count: Constants.numberOfMessagesToLoad, from: 0)
            .then { [weak self] context in
                self?.handle(action: .endBatchFetch(messageContext: context), context: batchContext)
            }
            .catch(on: .main) { [weak self] error in
                self?.handle(error: error)
            }
    }

    private func loadMore(_ batchContext: ASBatchContext?) {
        guard let totalNumberOfMessages = state.total else { return }

        let from = messages.count
        let diff = min(Constants.numberOfMessagesToLoad, totalNumberOfMessages - from)

        messageProvider
            .fetchMessages(for: viewModel.path, count: diff, from: from)
            .then { [weak self] context in
                self?.handle(action: .endBatchFetch(messageContext: context), context: batchContext)
            }
            .catch(on: .main) { [weak self] error in
                self?.handle(error: error)
            }
    }
}

extension InboxViewController {
    @objc private func handleInfoTap() {
        #warning("ToDo")
        showToast("Email us at human@flowcrypt.com")
    }

    @objc private func handleSearchTap() {
        #warning("ToDo")
        showToast("Search not implemented yet")
    }

    @objc private func refresh() {
        fetchAndRenderEmails(nil)
    }

    private func btnComposeTap() {
        TapTicFeedback.generate(.light)
        let composeVc = UIStoryboard.main.instantiate(ComposeViewController.self)
        navigationController?.pushViewController(composeVc, animated: true)
    }
}

extension InboxViewController {
    private func openMessageIfPossible(with message: MCOIMAPMessage) {
        if Int(message.size) > Constants.messageSizeLimit {
            showToast("Messages larger than 5MB are not supported yet")
        } else {
            let messageInput = MsgViewController.Input(
                objMessage: message,
                bodyMessage: nil,
                path: viewModel.path
            )
            let msgVc = MsgViewController.instance(with: messageInput) { [weak self] operation, message in
                self?.handleMessage(operation: operation, message: message)
            }
            navigationController?.pushViewController(msgVc, animated: true)
        }
    }

    private func handleMessage(operation: MsgViewController.MessageAction, message: MCOIMAPMessage) {
        guard let index = messages.firstIndex(of: message) else { return }
        switch operation {
        case .markAsRead: markAsRead(message: message, at: index)
        case .delete, .archive: delete(message: message, at: index)
        }
    }

    private func delete(message: MCOIMAPMessage, at index: Int) {
        messages.remove(at: index)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let self = self else { return }
            self.tableNode.deleteRows(at: [IndexPath(row: index, section: 0)], with: .left)
        }
    }

    private func markAsRead(message: MCOIMAPMessage, at index: Int) {
        messages[index] = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let self = self else { return }
            self.tableNode.reloadRows(at: [IndexPath(row: index, section: 0)], with: .fade)
        }
    }
}

extension InboxViewController: ASTableDataSource, ASTableDelegate {
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        switch state {
        case .empty: return 1
        case .idle: return 1
        case .tailFetching: return messages.count + 1
        case .fetched: return messages.count
        }
    }

    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        let height = tableNode.frame.size.height - 44.0
        let size = CGSize(width: tableNode.frame.size.width, height: height)
        let text = title ?? ""

        return { [weak self] in
            guard let self = self else { return ASCellNode() }

            switch self.state {
            case .empty:
                return TextCellNode(title: "\(text) is empty", withSpinner: false, size: size)
            case .idle:
                return TextCellNode(title: "Loading", withSpinner: false, size: size)
            case .fetched:
                return InboxCellNode(message: InboxCellNodeInput(self.messages[indexPath.row]))
            case .tailFetching:
                guard let message = self.messages[safe: indexPath.row] else {
                    return TextCellNode(title: "Loading ...", withSpinner: true, size: CGSize(width: 44, height: 44))
                }
                return InboxCellNode(message: InboxCellNodeInput(message))
            }
        }
    }

    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        tableNode.deselectRow(at: indexPath, animated: true)
        guard let message = messages[safe: indexPath.row] else { return }

        openMessageIfPossible(with: message)
    }
}

extension InboxViewController {
    func shouldBatchFetch(for tableNode: ASTableNode) -> Bool {
        switch state {
        case .idle:
            return true
        case .empty:
            return false
        case .fetched, .tailFetching:
            return messages.count < state.total ?? 0
        }
    }

    func tableNode(_ tableNode: ASTableNode, willBeginBatchFetchWith context: ASBatchContext) {
        context.beginBatchFetching()
        handle(action: .beginBatchFetch, context: context)
    }

    private func handle(action: Action, context: ASBatchContext?) {
        switch action {
        case .beginBatchFetch:
            handleBeginFetching(with: context)
        case let .endBatchFetch(messageContext):
            handleEndFetching(with: messageContext, context: context)
        }
    }

    private func handleBeginFetching(with context: ASBatchContext?) {
        switch state {
        case .fetched:
            loadMore(context)
            state = .tailFetching
            DispatchQueue.main.async {
                self.tableNode.reloadData()
            }
        default:
            fetchAndRenderEmails(context)
        }
    }

    private func handleEndFetching(with messageContext: MessageContext, context: ASBatchContext?) {
        if messages.isEmpty {
            if messageContext.messages.isEmpty {
                state = .empty
            } else {
                messages = messageContext.messages
                    .sorted(by: { $0.header.date > $1.header.date })
                state = .fetched(messageContext.totalMessages)
            }
            DispatchQueue.main.async {
                self.tableNode.reloadData()
            }
        } else {
            let count = messages.count - 1
            let indexesToInsert = messageContext.messages
                .enumerated()
                .map { (index, value) -> Int in
                    let indexInTableView = index + count
                    return indexInTableView
                }
                .map { IndexPath(row: $0, section: 0)}

            let indexesToDelete = [IndexPath(row: messages.count, section: 0)]

            messages.append(contentsOf: messageContext.messages)
            state = .fetched(messageContext.totalMessages)

            DispatchQueue.main.async {
                self.tableNode.performBatchUpdates({
                    self.tableNode.deleteRows(at: indexesToDelete, with: .fade)
                    self.tableNode.insertRows(at: indexesToInsert, with: .none)
                }, completion: { _ in

                })
            }
        }

        DispatchQueue.main.async {
            self.refreshControl.endRefreshing()
        }
        context?.completeBatchFetching(true)
    }

    private func handle(error: Error) {
        refreshControl.endRefreshing()
        showAlert(error: error, message: Language.failedToLoadMessages)
    }
}

