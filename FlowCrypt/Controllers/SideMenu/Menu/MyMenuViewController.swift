//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptUI
import Promises
import UIKit

final class MyMenuViewController: ASViewController<ASDisplayNode> {
    private enum Constants {
        static let allMail = "folder_all_mail".localized
        static let inbox = "folder_all_inbox".localized
        static let cellHeight: CGFloat = 60
    }

    enum Sections: Int, CaseIterable {
        case header = 0, folders, service
    }

    private let foldersProvider: FoldersProviderType
    private let dataService: DataServiceType
    private let userService: UserServiceType
    private let router: GlobalRouterType
    private let decorator: MyMenuViewDecoratorType

    private var folders: [FolderViewModel] = []
    private var serviceItems: [FolderViewModel] { FolderViewModel.menuItems
    }

    private let tableNode: ASTableNode

    init(
        foldersProvider: FoldersProviderType = FolderProvider(storage: DataService.shared.storage),
        dataService: DataServiceType = DataService.shared,
        userService: UserServiceType = UserService.shared,
        globalRouter: GlobalRouterType = GlobalRouter(),
        decorator: MyMenuViewDecoratorType = MyMenuViewDecorator(),
        tableNode: ASTableNode = TableNode()
    ) {
        self.foldersProvider = foldersProvider
        self.dataService = dataService
        self.userService = userService
        router = globalRouter
        self.decorator = decorator
        self.tableNode = tableNode
        super.init(node: ASDisplayNode())
    }

    required init?(coder _: NSCoder) {
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
            $0.view.alwaysBounceVertical = false
            $0.view.alwaysBounceHorizontal = false
            $0.backgroundColor = decorator.backgroundColor
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
                self?.handleError(with: error)
            }
    }

    private func handleNewFolders(with folders: [FolderViewModel]) {
        hideSpinner()
        self.folders = folders.sorted(
            by: { left, _ in
                if left.path.caseInsensitiveCompare(Constants.inbox) == .orderedSame {
                    return true
                } else if left.path.caseInsensitiveCompare(Constants.allMail) == .orderedSame {
                    return true
                }
                return false
            }
        )
        tableNode.reloadData()
    }

    private func handleError(with error: Error) {
        switch AppErr(error) {
        case .connection:
            hideSpinner()
        default:
            showAlert(error: error, message: "error_fetch_folders".localized)
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard #available(iOS 13.0, *) else { return }
        tableNode.reloadData()
    }
}

extension MyMenuViewController: ASTableDataSource, ASTableDelegate {
    func numberOfSections(in tableNode: ASTableNode) -> Int {
        Sections.allCases.count
    }

    func tableNode(_: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Sections.header.rawValue: return 1
        case Sections.folders.rawValue: return folders.count
        case Sections.service.rawValue: return serviceItems.count
        default: return 0
        }
    }

    func tableNode(_: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self = self else { return ASCellNode() }
            switch indexPath.section {
            case Sections.header.rawValue:
                return HeaderNode(
                    input: self.decorator.header(
                        for: self.dataService.currentUser?.name,
                        email: self.dataService.email
                    )
                )
            case Sections.folders.rawValue:
                return InfoCellNode(
                    input: self.folders[safe: indexPath.row]
                        .map(InfoCellNode.Input.init)
                )
            case Sections.service.rawValue:
                return InfoCellNode(
                    input: self.serviceItems[safe: indexPath.row]
                        .map(InfoCellNode.Input.init)
                )
            default:
                return ASCellNode()
            }
        }
    }

    func tableNode(_: ASTableNode, didSelectRowAt indexPath: IndexPath) {
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
            divider.backgroundColor = decorator.dividerColor
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
            sideMenuController()?.setContentViewController(SettingsViewController())
        case .logOut:
            self.router.wipeOutAndReset()
        }
    }
}

extension MyMenuViewController: SideMenuViewController {
    func didOpen() {
        if folders.isEmpty {
            fetchFolders()
        }
    }
}
