//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit
import Promises

class MyMenuTableViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet var menuTable: UITableView!
    @IBOutlet var lblName: UILabel!
    @IBOutlet var lblEmail: UILabel!

    var menuArray = [String]()
    var subMenuArray = NSMutableArray()
    var arrImap = [MCOIMAPFolder]()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        async({ try await(Imap.instance.fetchFolders()) }, then: { res in
            self.arrImap = res.folders
            self.menuArray = res.menu
            self.menuTable.reloadData()
        }, fail: Language.could_not_fetch_folders)
    }

    private func setupUI() {
         // show first name, save space
        let name = GoogleApi.instance
            .getName()
            .split(separator: " ")
            .first ?? ""
            .map(String.init)

        let email = GoogleApi.instance
            .getEmail()
            .replacingOccurrences(of: "@gmail.com", with: "")

        lblName.text = name
        lblEmail.text = email
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.hideSideMenuView()
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
        Imap.instance.totalNumberOfInboxMsgs = 0
        Imap.instance.messages.removeAll()
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
