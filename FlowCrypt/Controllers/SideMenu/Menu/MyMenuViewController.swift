//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit
import Promises
import AsyncDisplayKit

final class MyMenuViewController: ASViewController<ASDisplayNode> {
    private enum Constants {
        static let allMail = "folder_all_mail".localized
        static let inbox = "folder_all_inbox".localized
        static let cellHeight: CGFloat = 60
    }

    enum Sections: Int, CaseIterable {
        case header = 0, folders, service
    }

    private let foldersProvider: FoldersProvider
    private let dataManager: DataManagerType
    private let userService: UserServiceType
    private let router: GlobalRouterType

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
    private let tableNode: ASTableNode

    init(
        foldersProvider: FoldersProvider = Imap.instance,
        dataManager: DataManagerType = DataManager.shared,
        userService: UserServiceType = UserService.shared,
        globalRouter: GlobalRouterType = GlobalRouter(),
        tabelNode: ASTableNode = TableNode()
    ) {
        self.foldersProvider = foldersProvider
        self.dataManager = dataManager
        self.userService = userService
        self.router = globalRouter
        self.tableNode = tabelNode
        super.init(node: ASDisplayNode())
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Due to Bug in ENSideMenu
    // we need to use this property to setup UI in viewDidAppear
    // instead of viewDidload (ENSideMenu call self.view inside initializer)
    private var isFirstLaunch = true

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)


        if isFirstLaunch {
            setupUI()
            fetchFolders()
        }
        isFirstLaunch = false
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        tableNode.frame = CGRect(
            x: 0,
            y: -safeAreaWindowInsets.top,
            width: node.bounds.size.width,
            height: node.bounds.size.height + safeAreaWindowInsets.top
        )
    }

    private func setupUI() {
        node.addSubnode(tableNode)
        tableNode.setup {
            $0.dataSource = self
            $0.delegate = self
            $0.view.tableHeaderView = UIView().then {
                $0.backgroundColor = .main
                $0.frame.size.height = safeAreaWindowInsets.top
            }

            $0.reloadData()
        }
    }

    private func fetchFolders() {
        showSpinner()
        foldersProvider.fetchFolders()
            .then(on: .main) { [weak self] folders in
                self?.handleNewFolders(with: folders)
            }
            .catch { [weak self] error in
                self?.showAlert(error: error, message: "error_fetch_folders".localized)
            }
    }

    private func handleNewFolders(with result: FoldersContext) {
        hideSpinner()
        folders = result.folders
            .compactMap {
                FolderViewModel($0)
            }
            .sorted(by: { left, _ in
                if left.path.caseInsensitiveCompare(Constants.inbox) == .orderedSame {
                    return true
                } else if left.path.caseInsensitiveCompare(Constants.allMail) == .orderedSame {
                    return true
                }
                return false
            })
        tableNode.reloadData()
    }
}

extension MyMenuViewController: ASTableDataSource, ASTableDelegate {
    func numberOfSections(in tableNode: ASTableNode) -> Int {
        return Sections.allCases.count
    }

    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Sections.header.rawValue: return 1
        case Sections.folders.rawValue: return folders.count
        case Sections.service.rawValue: return serviceItems.count
        default: return 0
        }
    }

    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self = self else { return ASCellNode() }
            switch indexPath.section {
            case Sections.header.rawValue: return HeaderNode(input: self.headerViewModel)
            case Sections.folders.rawValue: return MenuNode(input: self.folders[safe: indexPath.row])
            case Sections.service.rawValue: return MenuNode(input: self.serviceItems[safe: indexPath.row])
            default: return ASCellNode()
            } 
        }

    }

    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
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

    func tableView(_: UITableView, viewForFooterInSection _: Int) -> UIView? {
        return UIView().then {
            let divider = UIView(frame: CGRect(x: 16, y: 0, width: view.frame.width - 16, height: 1))
            $0.addSubview(divider)
            $0.backgroundColor = .clear
            divider.backgroundColor = UIColor(white: 0, alpha: 0.1)
        }
    }

    func tableView(_: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return section == Sections.folders.rawValue ? 1 : 0
    }
}

extension MyMenuViewController {
    private func handleTapOn(folder: FolderViewModel) {
        switch folder.itemType {
        case .folder:
            let input = InboxViewModel(folder)
            sideMenuController()?.setContentViewController(InboxViewController(input))
        case .settings:
            showToast("Settings not yet implemented")
        case .logOut:
            userService.signOut()
                .then(on: .main) { [weak self] _ in
                    self?.router.reset()
                }.catch(on: .main) { [weak self] error in
                    self?.showAlert(error: error, message: "Could not log out")
                }
        }
    }
}
