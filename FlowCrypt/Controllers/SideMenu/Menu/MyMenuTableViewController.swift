//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit
import Promises

final class MyMenuTableViewController: UIViewController {
    private enum Constants {
        static let allMail = "All Mail"
        static let inbox = "Inbox"
        static let cellHeight: CGFloat = 60
    }

    enum Sections: Int, CaseIterable {
        case header = 0, folders, service
    }

    // TODO: Inject as a dependency
    private let foldersProvider: FoldersProvider = Imap.instance
    private let dataManager = DataManager.shared
    private let userService = UserService.shared
    private let router = GlobalRouter()

    private let tableView: UITableView = UITableView()

    private lazy var headerViewModel: MenuHeaderViewModel = {
        let name = dataManager.currentUser()?.name
            .split(separator: " ")
            .first
            .map(String.init) ?? ""

        let email = dataManager.currentUser()?.email
            .replacingOccurrences(of: "@gmail.com", with: "")

        return MenuHeaderViewModel(title: name, subtitle: email)
    }()
    private var folders: [FolderViewModel] = []
    private var serviceItems: [FolderViewModel] = FolderViewModel.menuItems()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        fetchFolders()
    }

    private func setupUI() {
        tableView.setup {
            $0.dataSource = self
            $0.delegate = self
            $0.register(cellType: MenuCell.self)
            $0.register(cellType: HeaderCell.self)
            $0.showsVerticalScrollIndicator = false
            $0.alwaysBounceVertical = false
            $0.separatorStyle = .none
            $0.reloadData()
        }
        view.addSubview(tableView)
        view.constrainToEdges(tableView, insets: UIEdgeInsets(top: -20, left: 0, bottom: 0, right: 0))
    }

    private func fetchFolders() {
        showSpinner()
        foldersProvider.fetchFolders()
            .then(on: .main) { [weak self] folders in
                self?.handleNewFolders(with: folders)
            }
            .catch { [weak self] error in
                self?.showAlert(error: error, message: Language.could_not_fetch_folders)
            }
    }

    private func handleNewFolders(with result: FoldersContext) {
        hideSpinner()
        folders = result.folders
            .compactMap {
                FolderViewModel($0)
            }
            .sorted(by: { (left, right) in
                if left.path.caseInsensitiveCompare(Constants.inbox) == .orderedSame {
                    return true
                } else if left.path.caseInsensitiveCompare(Constants.allMail) == .orderedSame {
                    return true
                }
                return false
            })
        tableView.reloadData()
    }
}

extension MyMenuTableViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return Sections.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Sections.header.rawValue: return 1
        case Sections.folders.rawValue: return folders.count
        case Sections.service.rawValue: return serviceItems.count
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case Sections.header.rawValue: return 110
        case Sections.folders.rawValue: return 40
        case Sections.service.rawValue: return 40
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case Sections.header.rawValue:
            return tableView.dequeueReusableCell(ofType: HeaderCell.self, at: indexPath)
                    .setup(with: headerViewModel)
        case Sections.folders.rawValue:
            return tableView.dequeueReusableCell(ofType: MenuCell.self, at: indexPath)
                .setup(with: folders[indexPath.row])
        case Sections.service.rawValue:
            return tableView.dequeueReusableCell(ofType: MenuCell.self, at: indexPath)
                .setup(with: serviceItems[indexPath.row])
        default:
            return tableView.dequeueReusableCell(ofType: MenuCell.self, at: indexPath)
        }

    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case Sections.folders.rawValue:
            guard let item = folders[safe: indexPath.row] else { return }
            handleTapOn(folder: item)
        case Sections.service.rawValue:
            guard let item = serviceItems[safe: indexPath.row] else { return }
            handleTapOn(folder: item)
        default:
            break
        }

    }

    private func handleTapOn(folder: FolderViewModel) {
        switch folder.itemType {
        case .folder:
            let input = InboxViewModel(folder)
            let inboxVc = InboxViewController.instance(with: input)
            sideMenuController()?.setContentViewController(inboxVc)
        case .settings:
            showToast("Settings not yet implemented")
        case .logOut:
            userService.signOut()
                .then(on: .main) { [weak self] _ in
                    self?.router.proceedAfterLogOut()
                }.catch(on: .main) { [weak self] error in
                    self?.showAlert(error: error, message: "Could not log out")
                }
        }

    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView().then {
            let divider = UIView(frame: CGRect(x: 16, y: 0, width: view.frame.width - 16, height: 1))
            $0.addSubview(divider)
            $0.backgroundColor = .clear
            divider.backgroundColor = UIColor(white: 0, alpha: 0.1)
        }
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return section == Sections.folders.rawValue ? 1 : 0
    }
}

