//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit
import Promises

final class MyMenuTableViewController: UIViewController {
    // TODO: Inject as a dependency
    private let imap = Imap.instance

    @IBOutlet var tableView: UITableView!
    @IBOutlet var lblName: UILabel!
    @IBOutlet var lblEmail: UILabel!

    private var context: FoldersContext? { didSet { tableView.reloadData()} }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        fetchFolders()
    }

    private func setupUI() {
         // show first name, save space
        let name = GoogleApi.instance
            .getName()
            .split(separator: " ")
            .first
            .map(String.init) ?? ""

        let email = GoogleApi.instance
            .getEmail()
            .replacingOccurrences(of: "@gmail.com", with: "")

        lblName.text = name
        lblEmail.text = email
    }

    private func fetchFolders() {
        imap.fetchFolders()
            .then(on: .main) { [weak self] res in
                self?.handleFolders(with: res)
            }
            .catch { [weak self] error in
                self?.showAlert(error: error, message: Language.could_not_fetch_folders)
            }
    }

    private func handleFolders(with result: FoldersContext) {
        context = result
        tableView.cellForRow(at: IndexPath(row: 0, section: 0))?.isSelected = true
    }

}

extension MyMenuTableViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return context?.menu.count ?? 0
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // TODO: - Add safe subscript
        guard let cell: MenuCell = self.tableView.dequeueReusableCell(withIdentifier: "MenuCell") as? MenuCell,
            let title = context?.menu[indexPath.row]
        else {
            assertionFailure()
            return UITableViewCell()
        }
        cell.lblName.text = title

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let context = context else { return }

        imap.totalNumberOfInboxMsgs = 0
        imap.messages.removeAll()

        // TODO: - Add safe subscript
        let input = InboxViewModel(
            folderName: context.menu[indexPath.row].capitalized,
            path: context.folders[indexPath.row].path
        )
        let inboxVc = InboxViewController.instance(with: input)
        sideMenuController()?.setContentViewController(inboxVc)
    }
}

final class MenuCell: UITableViewCell {
    @IBOutlet var lblName: UILabel!

    override func awakeFromNib() {
        selectionStyle = .none
    }
}


