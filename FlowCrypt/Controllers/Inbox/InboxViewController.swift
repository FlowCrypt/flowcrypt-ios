//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit
import MBProgressHUD
import Promises
import ENSwiftSideMenu


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
    }

    // TODO: Inject as a dependency
    private let imap = Imap.instance

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var lblEmptyMessage: UILabel!
    @IBOutlet weak var btnCompose: UIButton!

    private var messages = [MCOIMAPMessage]() {
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
            tableView.tableFooterView?.isHidden = canLoadMore
        }
    }

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

extension InboxViewController: MsgViewControllerDelegate {
    func movedOrUpdated(objMessage: MCOIMAPMessage) {
        guard let index = self.messages.firstIndex(of: objMessage) else { return }
        messages.remove(at: index)
        tableView.reloadData()
    }
}

extension InboxViewController {
    private func fetchAndRenderEmails(withSpinner isSpinnerShown: Bool) {
        if isSpinnerShown {
            showSpinner()
        } else if !refreshControl.isRefreshing {
            refreshControl.beginRefreshing()
        }

        imap.fetchLastMsgs(count: Constants.numberOfMessagesToLoad, folder: viewModel.path)
            .then(on: .main) { [weak self] messages in
                guard let self = self else { return }
                self.messages = messages
                self.tableView.reloadData()
            }
            .catch(on: .main) { [weak self] error in
                guard let self = self else { return }
                self.refreshControl.endRefreshing()
                self.showAlert(error: error, message: Language.failedToLoadMessages)
        }
    }

    private func loadMore() {
        canLoadMore = false
        loadMoreActivityIndicator.startAnimating()

        imap.fetchMoreMessages(count: Constants.numberOfMessagesToLoad, folder: viewModel.path)
            .then(on: .main) { [weak self] msgs in
                guard let self = self else { return }
                self.handleNew(messages: msgs)
            }
            .catch(on: .main) { [weak self] error in
                guard let self = self else { return }
                self.canLoadMore = true
                self.refreshControl.endRefreshing()
        }
    }

    private func handleNew(messages msgs: [MCOIMAPMessage]) {
        let count = messages.count - 1
        let indexesToUpdate = msgs.enumerated()
            .map { (index, value) -> Int in
                let indexInTableView = index + count
                return indexInTableView
            }
            .map { IndexPath(row: $0, section: 0)}
        print(indexesToUpdate)

        messages.append(contentsOf: msgs)
        tableView.insertRows(at: indexesToUpdate, with: .none)
        canLoadMore = true
        refreshControl.endRefreshing()
    }
}

extension InboxViewController {
    @objc private func handleInfoTap() {
        #warning("ToDo")
        showToast("Info not implemented yet")
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
        let messageInput = MsgViewController.Input(
            objMessage: messages[indexPath.row],
            bodyMessage: nil,
            path: viewModel.path
        )
        let msgVc = MsgViewController.instance(with: messageInput, delegate: self)
        navigationController?.pushViewController(msgVc, animated: true)
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
