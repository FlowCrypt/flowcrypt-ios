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
    }

    // TODO: Inject as a dependency
    private let imap = Imap.instance

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var lblEmptyMessage: UILabel!

    private var messages = [MCOIMAPMessage]() {
        didSet {
            lblEmptyMessage.isHidden = messages.count > 0
            refreshControl.endRefreshing()
            tableView.reloadData()
        }
    }
    private var viewModel = InboxViewModel.empty
    private let refreshControl = UIRefreshControl()

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let titleText = viewModel.folderName.isEmpty ? "Inbox" : viewModel.folderName
        title = titleText
        
        lblEmptyMessage.text = "\(titleText) is empty"
        lblEmptyMessage.isHidden = true
        
        tableView.register(UINib(nibName: "InboxTableViewCell", bundle: nil), forCellReuseIdentifier: "InboxTableViewCell")
        tableView.tableFooterView = UIView()
        
        fetchAndRenderEmails()
        configureNavigationBar()
        configureRefreshControl()
    }
    
    private func configureRefreshControl() {
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        sideMenuController()?.sideMenu?.allowPanGesture = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        sideMenuController()?.sideMenu?.allowPanGesture = false
        tableView.reloadData()
    }

    private func configureNavigationBar() {
        navigationItem.rightBarButtonItem = NavigationBarItemsView(
            with: [
                NavigationBarItemsView.Input(image: UIImage(named: "help_icn"), action: (self, #selector(handleInfoTap))),
                NavigationBarItemsView.Input(image: UIImage(named: "search_icn"), action: (self, #selector(handleSearchTap)))
            ]
        )

        navigationItem.leftBarButtonItem = NavigationBarActionButton(UIImage(named: "menu_icn")) { [weak self] in
            self?.toggleSideMenuView()
        }
    }

    private func fetchAndRenderEmails() {
        showSpinner()

        imap.fetchLastMsgs(count: Constants.numberOfMessagesToLoad, folder: viewModel.path)
            .then(on: .main) { [weak self] messages in
                guard let self = self else { return }
                self.hideSpinner()
                self.messages = messages
            }
            .catch(on: .main) { [weak self] error in
                guard let self = self else { return }
                self.refreshControl.endRefreshing()
                self.showAlert(error: error, message: Language.failedToLoadMessages)
            }
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
    @objc private func handleInfoTap() {
        #warning("ToDo")
        showToast("Info not implemented yet")
    }

    @objc private func handleSearchTap() {
        #warning("ToDo")
        showToast("Search not implemented yet")
    }
    
    @objc private func refresh() {
        fetchAndRenderEmails()
    }

    @IBAction func btnComposeTap(sender: AnyObject) {
        let composeVc = UIStoryboard.main.instantiate(ComposeViewController.self)
        navigationController?.pushViewController(composeVc, animated: true)
    }
}

extension InboxViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.messages.count
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
        return 90.0
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
