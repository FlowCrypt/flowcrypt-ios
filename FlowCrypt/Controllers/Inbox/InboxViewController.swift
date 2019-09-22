//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit
import Promises
import RxSwift

extension InboxViewController {
    static func instance(with input: InboxViewModel) -> InboxViewController {
        let vc = UIStoryboard.main.instantiate(InboxViewController.self)
        vc.viewModel = input
        return vc
    }
}

final class InboxViewController: UIViewController {
    private enum Constants {
        static let numberOfMessagesToLoad = 10
        static let inboxCellHeight: CGFloat = 90.0
        static let loadMoreTreshold: CGFloat = 300
        static let messageSizeLimit: Int = 5_000_000
    }

    private let messageProvider: MessageProvider = DefaultMessageProvider()
    private let disposeBag = DisposeBag()

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var lblEmptyMessage: UILabel!
    @IBOutlet weak var btnCompose: UIButton!

    private var messages: [MCOIMAPMessage] = [] {
        didSet {
            lblEmptyMessage.isHidden = messages.count > 0
            refreshControl.endRefreshing()
            hideSpinner()
        }
    }
    private var viewModel = InboxViewModel.empty

    private let refreshControl = UIRefreshControl()
    private let loadMoreActivityIndicator = UIActivityIndicatorView(style: .gray)
    private var loadMoreInPosition = false
    private var canLoadMore = true {
        didSet {
            tableView.tableFooterView?.isHidden = !canLoadMore
        }
    }
    private var totalNumberOfMessages = 0

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupNavigationBar()
        fetchAndRenderEmails(withSpinner: true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
}

extension InboxViewController {
    private func setupUI() {
        let titleText = viewModel.folderName.isEmpty ? "Inbox" : viewModel.folderName
        title = titleText

        lblEmptyMessage.text = "\(titleText) is empty"
        lblEmptyMessage.isHidden = true


        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
        tableView.register(UINib(nibName: "InboxTableViewCell", bundle: nil), forCellReuseIdentifier: "InboxTableViewCell")

        view.bringSubviewToFront(btnCompose)

        loadMoreActivityIndicator.frame = CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 50)
        tableView.tableFooterView = loadMoreActivityIndicator
        tableView.tableFooterView?.isHidden = true
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
    private func fetchAndRenderEmails(withSpinner isSpinnerShown: Bool) {
        if isSpinnerShown {
            showSpinner()
        } else if !refreshControl.isRefreshing {
            refreshControl.beginRefreshing()
        }

        messageProvider
            .fetchMessages(for: viewModel.path, count: Constants.numberOfMessagesToLoad, from: 0)
            .observeOn(MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] context in
                    guard let self = self else { return }
                    self.messages = context.messages.sorted(by: { $0.header.date > $1.header.date })
                    self.canLoadMore = self.messages.count < context.totalMessages
                    self.totalNumberOfMessages = context.totalMessages
                    self.tableView.reloadData()
                },
                onError: { [weak self] error in
                    self?.refreshControl.endRefreshing()
                    self?.showAlert(error: error, message: Language.failedToLoadMessages)
                })
            .disposed(by: disposeBag)
    }

    private func loadMore() {
        guard canLoadMore else { return }
        loadMoreActivityIndicator.startAnimating()


        let from = messages.count
        let diff = min(Constants.numberOfMessagesToLoad, totalNumberOfMessages - from)

        messageProvider
            .fetchMessages(for: viewModel.path, count: diff, from: from)
            .observeOn(MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] context in
                    self?.handleNew(messages: context)
                },
                onError: { [weak self] error in
                    self?.canLoadMore = true
                    self?.refreshControl.endRefreshing()
                })
            .disposed(by: disposeBag)
    }

    private func handleNew(messages context: MessageContext) {
        let count = messages.count - 1
        let indexesToUpdate = context.messages.enumerated()
            .map { (index, value) -> Int in
                let indexInTableView = index + count
                return indexInTableView
            }
            .map { IndexPath(row: $0, section: 0)}
        messages.append(contentsOf: context.messages)
        tableView.insertRows(at: indexesToUpdate, with: .none)
        canLoadMore = messages.count < context.totalMessages
        totalNumberOfMessages = context.totalMessages
        refreshControl.endRefreshing()
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
        fetchAndRenderEmails(withSpinner: false)
    }

    @IBAction func btnComposeTap(sender: AnyObject) {
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
            self.tableView.beginUpdates()
            self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .left)
            self.tableView.endUpdates()
        }
    }

    private func markAsRead(message: MCOIMAPMessage, at index: Int) {
        messages[index] = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let self = self else { return }
            self.tableView.beginUpdates()
            self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .fade)
            self.tableView.endUpdates()
        }
    }
}

extension InboxViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell: InboxTableViewCell = tableView.dequeueReusableCell(withIdentifier: "InboxTableViewCell", for: indexPath) as? InboxTableViewCell
            else {
                assertionFailure("Couldn't dequeueReusableCell cell \(self.debugDescription)")
                return UITableViewCell()
        }
        cell.message = messages[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Constants.inboxCellHeight
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return Constants.inboxCellHeight
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let message = messages[safe: indexPath.row] else { return }

        openMessageIfPossible(with: message)
    }
}

extension InboxViewController: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let y = scrollView.contentOffset.y
        let height = scrollView.contentSize.height - scrollView.bounds.height - Constants.loadMoreTreshold
        
        if scrollView.contentSize.height > scrollView.bounds.height {
            if y > height {
                if !loadMoreInPosition {
                    loadMore()
                }
                loadMoreInPosition = true
            }
            else {
                loadMoreInPosition = false
            } 
        }
    }
}
