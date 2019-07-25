//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit
import MBProgressHUD


class InboxViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource, ENSideMenuDelegate, MsgViewControllerDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var lblEmptyMessage: UILabel!
    var messages = [MCOIMAPMessage]()
    var iMapFolderName = ""
    var path = ""

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sideMenuController()?.sideMenu?.allowslideGesture = true
        if iMapFolderName == "" {
            self.title = "Inbox"
        } else {
            self.title = iMapFolderName
        }
        self.lblEmptyMessage.text = self.title! + " is empty"
        self.lblEmptyMessage.isHidden = true
        self.tableView.register(UINib(nibName: "InboxTableViewCell", bundle: nil), forCellReuseIdentifier: "InboxTableViewCell")
        self.tableView.tableFooterView = UIView()
        self.sideMenuController()?.sideMenu?.delegate = self

        if self.iMapFolderName == "" {
            self.path = "INBOX"
        }
        self.fetchEmailByImap()
        ToastManager.shared.tapToDismissEnabled = true
    }

    func fetchEmailByImap() {
        let spinnerActivity = MBProgressHUD.showAdded(to: self.view, animated: true)
        spinnerActivity.label.text = "Loading"
        spinnerActivity.isUserInteractionEnabled = false
        EmailProvider.sharedInstance.fetchLastMessages(nMessage: Constants.NUMBER_OF_MESSAGES_TO_LOAD, folderName: self.path) { (messages: [Any]?, error: Error?) in
            spinnerActivity.hide(animated: true)
            if error == nil {
                if messages == nil {
                    self.lblEmptyMessage.isHidden = false
                }
                if let messages = messages as? [MCOIMAPMessage] {
                    self.messages = messages
                    self.lblEmptyMessage.isHidden = true
                    self.tableView.reloadData()
                }
            } else {
                // todo - handle this proactively instead of waiting for failure, based on access token expiration
                // todo - would this fail on non-english phones? Any other way to catch the right error?
                // todo - this can cause infinite loop, where is the auth renew handling?
                if error?.localizedDescription == "Unable to authenticate with the current session's credentials." {
                    self.fetchEmailByImap()
                    return
                }
                self.showErrAlert(Language.failed_to_load_messages + ": \(error!)", onOk: nil)
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = false
        self.sideMenuController()?.sideMenu?.allowslideGesture = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        self.sideMenuController()?.sideMenu?.allowslideGesture = false
        self.tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func btnMenuTap(sender: AnyObject) { //To open/close menu
        toggleSideMenuView()
    }

    @IBAction func btnComposeTap(sender: AnyObject) {
        let composeVc = self.instantiate(viewController: ComposeViewController.self)
        self.navigationController?.pushViewController(composeVc, animated: true)
    }

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
        let msgVc = self.instantiate(viewController: MsgViewController.self)
        msgVc.objMessage = self.messages[indexPath.row]
        msgVc.path = self.path
        msgVc.delegate = self
        self.navigationController?.pushViewController(msgVc, animated: true)
    }

    func movedOrDeleted(objMessage: MCOIMAPMessage) {
        let index = self.messages.firstIndex(of: objMessage)
        self.messages.remove(at: index!)
        self.tableView.reloadData()
    }
}
