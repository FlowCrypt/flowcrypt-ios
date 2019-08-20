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
    
    var btnInfo: UIButton!
    var btnSearch: UIButton!
    var btnMenu: UIButton!
    
    var messages = [MCOIMAPMessage]()
    var iMapFolderName = ""
    var path = ""

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
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
        tableView.tableFooterView = UIView()
        
        fetchAndRenderEmails()
        configureNavigationBar()
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
            self.tableView.reloadData()
        }, fail: Language.failed_to_load_messages)
    }
    
    private func configureNavigationBar() {
        btnInfo = UIButton(type: .system)
        btnInfo.setImage(UIImage(named: "help_icn")!, for: .normal)
        btnInfo.imageEdgeInsets = Constants.rightUiBarButtonItemImageInsets
        btnInfo.frame = Constants.uiBarButtonItemFrame
        btnInfo.addTarget(self, action: #selector(btnInfoTap), for: .touchUpInside)
        
        btnSearch = UIButton(type: .system)
        btnSearch.setImage(UIImage(named: "search_icn")!, for: .normal)
        btnSearch.imageEdgeInsets = Constants.rightUiBarButtonItemImageInsets
        btnSearch.frame = Constants.uiBarButtonItemFrame
        btnSearch.addTarget(self, action: #selector(btnSearchTap), for: .touchUpInside)
        
        let stackView = UIStackView(arrangedSubviews: [btnInfo, btnSearch])
        stackView.distribution = .equalSpacing
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 15
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: stackView)
        
        btnMenu = UIButton(type: .system)
        btnMenu.setImage(UIImage(named: "menu_icn")!, for: .normal)
        btnMenu.imageEdgeInsets = Constants.leftUiBarButtonItemImageInsets
        btnMenu.frame = Constants.uiBarButtonItemFrame
        btnMenu.addTarget(self, action: #selector(btnMenuTap), for: .touchUpInside)
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: btnMenu)
        
    }
    
    @objc
    private func btnInfoTap() {
        #warning("ToDo")
    }
    
    @objc
    private func btnSearchTap() {
        #warning("ToDo")
    }
    
    @objc
    private func btnMenuTap() {
        toggleSideMenuView()
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
        return self.messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: InboxTableViewCell = tableView.dequeueReusableCell(withIdentifier: "InboxTableViewCell", for: indexPath) as! InboxTableViewCell
        cell.message = self.messages[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let msgVc = instantiate(viewController: MsgViewController.self)
        msgVc.objMessage = messages[indexPath.row]
        msgVc.path = path
        msgVc.delegate = self
        self.navigationController?.pushViewController(msgVc, animated: true)
    }
    
}
