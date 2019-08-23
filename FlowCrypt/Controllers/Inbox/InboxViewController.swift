//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit
import MBProgressHUD
import Promises
import Toast
import ENSwiftSideMenu

final class InboxViewController: BaseViewController, MsgViewControllerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var lblEmptyMessage: UILabel!
    @IBOutlet weak var btnCompose: UIButton!
    
    private var refreshControl: UIRefreshControl!
    private var btnInfo: UIButton!
    private var btnSearch: UIButton!
    private var btnMenu: UIButton!
    private var loadMoreActivityIndicator: UIActivityIndicatorView!
    
    // Infiniti scroll variables
    private var loadMoreInPosition = false
    private var countData = 0
    private var canLoadMore = true
    
    var messages = [MCOIMAPMessage]()
    var iMapFolderName = ""
    var path = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // TODO: closing side menu won't work, to be fixed in https://github.com/FlowCrypt/flowcrypt-ios/issues/38
        sideMenuController()?.sideMenu?.allowPanGesture = true
        
        title = iMapFolderName == "" ? "Inbox" : iMapFolderName
        if iMapFolderName == "" {
            path = "INBOX"
        }
        
        lblEmptyMessage.text =  "\(self.title!) is empty"
        lblEmptyMessage.isHidden = true
        
        tableView.register(UINib(nibName: "InboxTableViewCell", bundle: nil), forCellReuseIdentifier: "InboxTableViewCell")
        view.bringSubviewToFront(btnCompose)
        
        fetchAndRenderEmails()
        configureNavigationBar()
        configureRefreshControl()
        configureLoadMoreIndicator()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
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
    
    func movedOrUpdated(objMessage: MCOIMAPMessage) {
        guard let index = self.messages.firstIndex(of: objMessage) else { return }
        messages.remove(at: index)
        tableView.reloadData()
    }
    
    func fetchAndRenderEmails() {
        let spinnerActivity = MBProgressHUD.showAdded(to: self.view, animated: true)
        spinnerActivity.label.text = "Loading"
        spinnerActivity.isUserInteractionEnabled = false
        self.async({
            self.messages = try await(Imap.instance.fetchLastMsgs(count: Constants.NUMBER_OF_MESSAGES_TO_LOAD, folder: self.path))
        }, then: {
            spinnerActivity.hide(animated: true)
            self.lblEmptyMessage.isHidden = self.messages.count > 0
            self.updateTableView()
        }, fail: Language.failed_to_load_messages)
    }
    
    private func configureRefreshControl() {
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        tableView.addSubview(refreshControl)
    }
    
    private func updateTableView() {
        if countData == 0 {
            self.countData = self.messages.count
            tableView.reloadData()
        }
        else {
            self.tableView.performBatchUpdates({
                self.tableView.insertRows(at: (self.countData..<self.messages.count).map({ IndexPath(row: $0, section: 0) }), with: .none)
                self.countData = self.messages.count
            })
        }
    }
    
    // TODO: Refactor due to https://github.com/FlowCrypt/flowcrypt-ios/issues/38
    private func configureNavigationBar() {
        
        btnInfo = UIButton(type: .system)
        btnInfo.setImage(UIImage(named: "help_icn")!, for: .normal)
        btnInfo.imageEdgeInsets = Constants.rightUiBarButtonItemImageInsets
        btnInfo.addTarget(self, action: #selector(btnInfoTap), for: .touchUpInside)
        
        btnSearch = UIButton(type: .system)
        btnSearch.setImage(UIImage(named: "search_icn")!, for: .normal)
        btnSearch.imageEdgeInsets = Constants.rightUiBarButtonItemImageInsets
        btnSearch.addTarget(self, action: #selector(btnSearchTap), for: .touchUpInside)
        
        btnMenu = UIButton(type: .system)
        btnMenu.setImage(UIImage(named: "menu_icn")!, for: .normal)
        btnMenu.imageEdgeInsets = Constants.leftUiBarButtonItemImageInsets
        btnMenu.addTarget(self, action: #selector(btnMenuTap), for: .touchUpInside)
        
        let navigationBarButtons = [btnInfo, btnSearch, btnMenu]
        
        for button in navigationBarButtons {
            NSLayoutConstraint.activate(
                [
                    (button?.widthAnchor.constraint(equalToConstant: Constants.uiBarButtonItemSize))!,
                    (button?.heightAnchor.constraint(equalToConstant: Constants.uiBarButtonItemSize))!
                ]
            )
        }
        
        let stackView = UIStackView(arrangedSubviews: [btnInfo, btnSearch])
        stackView.distribution = .equalSpacing
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = Constants.navigationBarInteritemSpacing
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: stackView)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: btnMenu)
    }
    
    private func configureLoadMoreIndicator() {
        loadMoreActivityIndicator = UIActivityIndicatorView(style: .gray)
        loadMoreActivityIndicator.frame = CGRect(x: CGFloat(0), y: CGFloat(0), width: self.tableView.bounds.width, height: CGFloat(50))
        tableView.tableFooterView = loadMoreActivityIndicator
        tableView.tableFooterView?.isHidden = true
    }
    
    @objc
    private func btnInfoTap() {
        #warning("ToDo")
        showToast("Info not implemented yet")
    }
    
    @objc
    private func btnSearchTap() {
        #warning("ToDo")
        showToast("Search not implemented yet")
    }
    
    @objc
    private func btnMenuTap() {
        toggleSideMenuView()
    }
    
    @objc
    private func refresh() {
        self.async({ [weak self] in
            guard let `self` = self else { return }
            self.messages = try await(Imap.instance.fetchLastMsgs(count: self.messages.count, folder: self.path))
            }, then: { _ in
                self.refreshControl.endRefreshing()
                self.updateTableView()
        }, fail: { _ in
            self.refreshControl.endRefreshing()
        })
    }
    
    @IBAction func btnComposeTap(sender: AnyObject) {
        let composeVc = self.instantiate(viewController: ComposeViewController.self)
        self.navigationController?.pushViewController(composeVc, animated: true)
    }
}


extension InboxViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int { // Table view data source
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.countData
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
        let msgVc = instantiate(viewController: MsgViewController.self)
        msgVc.objMessage = messages[indexPath.row]
        msgVc.path = path
        msgVc.delegate = self
        self.navigationController?.pushViewController(msgVc, animated: true)
    }
    
}

extension InboxViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        let y = scrollView.contentOffset.y
        let height = scrollView.contentSize.height - scrollView.bounds.height - 300
        
        if (scrollView.contentSize.height > scrollView.bounds.height) {
            if (y > height) {
                if (!loadMoreInPosition) {
                    loadMore()
                }
                loadMoreInPosition = true
            }
            else {
                loadMoreInPosition = false
            }
        }
    }
    
    func loadMore() {
        self.async({
            self.canLoadMore = false
            DispatchQueue.main.async {
                self.tableView.tableFooterView?.isHidden = false
                self.loadMoreActivityIndicator.startAnimating()
            }
            self.messages = try await(Imap.instance.fetchMoreMessages(count: Constants.NUMBER_OF_MESSAGES_TO_LOAD, folder: self.path))
        }, then: { _ in
            self.canLoadMore = true
            self.tableView.tableFooterView?.isHidden = true
            self.updateTableView()
        }, fail: { _ in
            self.canLoadMore = true
            self.tableView.tableFooterView?.isHidden = true
            self.refreshControl.endRefreshing()
        })
    }
    
}
