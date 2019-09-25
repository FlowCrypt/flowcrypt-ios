//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit
import Promises
import RxSwift
import AsyncDisplayKit

final class InboxViewController: ASViewController<ASDisplayNode> {
    private enum Constants {
        static let numberOfMessagesToLoad = 10
        static let inboxCellHeight: CGFloat = 90.0
        static let loadMoreTreshold: CGFloat = 300
        static let messageSizeLimit: Int = 5_000_000
    }

    enum State {
        case idle, empty, fetching, fetched(_ hasMore: Bool)
    }

    enum Action {
        case beginBatchFetch
        case endBatchFetch(hasMore: Bool)
    }

    private var state: State = .idle

    private let messageProvider: MessageProvider = DefaultMessageProvider()
    private let disposeBag = DisposeBag()

    private var tableNode: ASTableNode
    private lazy var composeButton = ComposeButtonNode() { [weak self] in
        self?.btnComposeTap()
    }

    private var messages: [MCOIMAPMessage] = [] {
        didSet {
//            lblEmptyMessage.isHidden = messages.count > 0
            refreshControl.endRefreshing()
            hideSpinner()
        }
    }
    private var viewModel: InboxViewModel

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
        let titleText = viewModel.folderName.isEmpty ? "Inbox" : viewModel.folderName
        title = titleText

        node.addSubnode(tableNode)
        node.addSubnode(composeButton)

//        lblEmptyMessage.text = "\(titleText) is empty"
//        lblEmptyMessage.isHidden = true


        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
//        tableNode.refreshControl = refreshControl


//        loadMoreActivityIndicator.frame = CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 50)
//        tableView.tableFooterView = loadMoreActivityIndicator
//        tableView.tableFooterView?.isHidden = true
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
    private func fetchAndRenderEmails(_ batchContext: ASBatchContext) {
//        InboxViewController.fetchDataWithCompletion { resultCount in
//            let action = Action.endBatchFetch(resultCount: resultCount)
//            let oldState = self.state
//            self.state = ViewController.handleAction(action, fromState: oldState)
//            self.renderDiff(oldState)
//            context.completeBatchFetching(true)
//        }



//        if isSpinnerShown {
//            showSpinner()
//        } else if !refreshControl.isRefreshing {
//            refreshControl.beginRefreshing()
//        }

        messageProvider
            .fetchMessages(for: viewModel.path, count: Constants.numberOfMessagesToLoad, from: 0)
            .observeOn(MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] context in
                    guard let self = self else { return }

                    self.messages = context.messages.sorted(by: { $0.header.date > $1.header.date })
                    let hasMore = self.messages.count < context.totalMessages
                    self.handleAction(.endBatchFetch(hasMore: hasMore), context: batchContext)

//                    let action = Action.endBatchFetch(resultCount: context.messages.count)
//                    let oldState = self.state
//                    self.state = InboxViewController.handleAction(action, fromState: oldState)
//                    self.renderDiff(oldState)
//                    batchContext.completeBatchFetching(true)




//                    self.messages = context.messages.sorted(by: { $0.header.date > $1.header.date })
//                    self.canLoadMore = self.messages.count < context.totalMessages
//                    self.totalNumberOfMessages = context.totalMessages
//                    self.tableNode.reloadData()
                },
                onError: { [weak self] error in
                    self?.refreshControl.endRefreshing()
                    self?.showAlert(error: error, message: Language.failedToLoadMessages)
                })
            .disposed(by: disposeBag)
    }

//    private func loadMore() {
//        guard canLoadMore else { return }
//        loadMoreActivityIndicator.startAnimating()
//
//
//        let from = messages.count
//        let diff = min(Constants.numberOfMessagesToLoad, totalNumberOfMessages - from)
//
//        messageProvider
//            .fetchMessages(for: viewModel.path, count: diff, from: from)
//            .observeOn(MainScheduler.instance)
//            .subscribe(
//                onNext: { [weak self] context in
//                    self?.handleNew(messages: context)
//                },
//                onError: { [weak self] error in
//                    self?.canLoadMore = true
//                    self?.refreshControl.endRefreshing()
//                })
//            .disposed(by: disposeBag)
//    }
//
//    private func handleNew(messages context: MessageContext) {
//        let count = messages.count - 1
//        let indexesToUpdate = context.messages.enumerated()
//            .map { (index, value) -> Int in
//                let indexInTableView = index + count
//                return indexInTableView
//            }
//            .map { IndexPath(row: $0, section: 0)}
//        messages.append(contentsOf: context.messages)
//        tableNode.insertRows(at: indexesToUpdate, with: .none)
//        canLoadMore = messages.count < context.totalMessages
//        totalNumberOfMessages = context.totalMessages
//        refreshControl.endRefreshing()
//    }
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
//        fetchAndRenderEmails(withSpinner: false)
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


extension InboxViewController: ASTableDataSource {
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    func tableView(_ tableView: ASTableView, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let message = self?.messages[safe: indexPath.row] else { return ASCellNode() }
            return InboxCellNode(message: InboxCellNodeInput(message))
        }
    }
}

extension InboxViewController: ASTableDelegate {
    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        tableNode.deselectRow(at: indexPath, animated: true)
        guard let message = messages[safe: indexPath.row] else { return }

        openMessageIfPossible(with: message)
    }

    func shouldBatchFetch(for tableNode: ASTableNode) -> Bool {
        switch state {
        case .idle:
            return true
        case .fetching:
            return false
        case let .fetched(hasMore):
            return hasMore
        case .empty:
            return false
        }
    }

    func tableNode(_ tableNode: ASTableNode, willBeginBatchFetchWith context: ASBatchContext) {
        handleAction(.beginBatchFetch, context: context)
    }
}

extension InboxViewController {
    private func handleAction(_ action: Action, context: ASBatchContext) {
        print("^^ \(action) self \(state)")

        switch (state, action) {
        case (.idle, .beginBatchFetch):
            self.state = .fetching
            fetchAndRenderEmails(context)
        case let (_ ,.endBatchFetch(hasMore)):
            self.state = .fetched(hasMore)
            tableNode.reloadData()
            context.completeBatchFetching(true)
        default:
            break
        }
    }

    private func renderDiff(_ oldState: State) {
        tableNode.reloadData()


//        self.tableNode.performBatchUpdates({
//            let rowCountChange = state.itemCount - oldState.itemCount
//            if rowCountChange > 0 {
//                let indexPaths = (oldState.itemCount..<state.itemCount).map { index in
//                    IndexPath(row: index, section: 0)
//                }
//                tableNode.insertRows(at: indexPaths, with: .none)
//            } else if rowCountChange < 0 {
//                assertionFailure("Deleting rows is not implemented. YAGNI.")
//            }
//
//            // Add or remove spinner.
//            if state.fetchingMore != oldState.fetchingMore {
//                if state.fetchingMore {
//                    // Add spinner.
//                    let spinnerIndexPath = IndexPath(row: state.itemCount, section: 0)
//                    tableNode.insertRows(at: [ spinnerIndexPath ], with: .none)
//                } else {
//                    // Remove spinner.
//                    let spinnerIndexPath = IndexPath(row: oldState.itemCount, section: 0)
//                    tableNode.deleteRows(at: [ spinnerIndexPath ], with: .none)
//                }
//            }
//        }, completion:nil)
    }
}


