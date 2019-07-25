//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit

class MyMenuTableViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet var menuTable: UITableView!
    var menuArray = [String]()
    var subMenuArray = NSMutableArray()
    var arrImap = [MCOIMAPFolder]()
    @IBOutlet var lblName: UILabel!
    @IBOutlet var lblEmail: UILabel!

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.fetchImapFolders()
        self.lblName.text = GoogleApi.instance.getName()
        self.lblEmail.text = GoogleApi.instance.getEmail()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.hideSideMenuView()
    }

    func fetchImapFolders() {
        EmailProvider.sharedInstance.fetchFolder { (folders, menuarr, error) in
            if menuarr != nil {
                self.arrImap = folders! as [MCOIMAPFolder]
                self.menuArray = menuarr!
                self.menuTable.reloadData()
            } else if error != nil {
                print("Imap folder error", error!)
                if error?.localizedDescription == "Unable to authenticate with the current session's credentials." {
                    self.fetchImapFolders()
                    return
                }
            }
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.menuArray.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: ProfileCell = self.menuTable.dequeueReusableCell(withIdentifier: "ProfileCell") as! ProfileCell
        cell.lblName.text = self.menuArray[indexPath.row]
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        EmailProvider.sharedInstance.totalNumberOfInboxMessages = 0
        EmailProvider.sharedInstance.messages.removeAll()
        let inboxVc = self.instantiate(viewController: InboxViewController.self)
        inboxVc.iMapFolderName = self.menuArray[indexPath.row].capitalized
        inboxVc.path = self.arrImap[indexPath.row].path
        self.sideMenuController()?.setContentViewController(inboxVc)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

class ProfileCell: UITableViewCell {
    @IBOutlet var profileImage: UIImageView!
    @IBOutlet var lblName: UILabel!
    @IBOutlet var lblEmail: UILabel!

    override func awakeFromNib() {
    }
}

class textCell: UITableViewCell {
    @IBOutlet var lblText: UILabel!
}
