//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptUI
import UIKit

/**
 * Menu view controller
 * Represents User folders and menu buttons like log out and settings
 * User see this screen when taps the burger menu
 * On tap on each folder user should be redirected to `InboxViewController` with selected folder
 * On settings tap user will be redirected to `SettingsViewController`
 */
@MainActor
final class MyMenuViewController: ViewController {
    private enum Constants {
        static let allMail = "folder_all_mail".localized
        static let inbox = "folder_all_inbox".localized
    }

    private enum Sections: Int, CaseIterable {
        case header = 0, main, additional
    }

    private enum State {
        case folders
        case accountAdding

        var arrowImage: UIImage? {
            switch self {
            case .folders: return UIImage(named: "arrow_down")?.tinted(.white)
            case .accountAdding: return UIImage(named: "arrow_up")?.tinted(.white)
            }
        }
    }

    private let appContext: AppContextWithUser
    private let foldersManager: FoldersManagerType
    private let decorator: MyMenuViewDecorator

    private var folders: [FolderViewModel] = []
    private var serviceItems: [FolderViewModel] { FolderViewModel.menuItems }
    private var accounts: [User] {
        do {
            return try appContext.encryptedStorage.getAllUsers()
                .filter { $0.email != appContext.user.email }
                .filter { try appContext.encryptedStorage.doesAnyKeypairExist(for: $0.email) }
        } catch {
            showAlert(message: error.localizedDescription)
            return []
        }
    }

    private let tableNode: ASTableNode

    private var state: State = .folders {
        didSet { tableNode.reloadData() }
    }

    // Due to Bug in ENSideMenu
    // we need to use this property to setup UI in viewDidAppear
    // instead of viewDidload (ENSideMenu call self.view inside initializer)
    private var isFirstLaunch = true

    init(
        appContext: AppContextWithUser,
        decorator: MyMenuViewDecorator = MyMenuViewDecorator(),
        tableNode: ASTableNode = TableNode()
    ) throws {
        self.appContext = appContext
        self.foldersManager = try appContext.getFoldersManager()
        self.decorator = decorator
        self.tableNode = tableNode
        super.init(node: ASDisplayNode())
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if isFirstLaunch {
            setupUI()
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

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        tableNode.reloadData()
    }
}

// MARK: - ASTableDataSource, ASTableDelegate
extension MyMenuViewController: ASTableDataSource, ASTableDelegate {
    func numberOfSections(in tableNode: ASTableNode) -> Int {
        Sections.allCases.count
    }

    func tableNode(_: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        guard let sections = Sections(rawValue: section) else { return 0 }

        switch (sections, state) {
        case (.header, _): return 1
        case (.main, .accountAdding): return accounts.count
        case (.main, .folders): return folders.count
        case (.additional, .accountAdding): return 1
        case (.additional, .folders): return serviceItems.count
        }
    }

    func tableNode(_: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self, let section = Sections(rawValue: indexPath.section) else {
                return ASCellNode()
            }
            return self.node(for: section, row: indexPath.row)
        }
    }

    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        guard let sections = Sections(rawValue: indexPath.section) else { return }

        switch (sections, state) {
        case (.header, _):
            guard let header = tableNode.nodeForRow(at: indexPath) as? TextImageNode else {
                return
            }
            handleTapOn(header: header)
        case (.main, .folders):
            guard let item = folders[safe: indexPath.row] else { return }
            handleFolderTap(with: item)
        case (.main, .accountAdding):
            handleAccountTap(with: indexPath.row)
        case (.additional, .folders):
            guard let item = serviceItems[safe: indexPath.row] else { return }
            handleFolderTap(with: item)
        case (.additional, .accountAdding):
            addAccount()
        }
    }

    func tableView(_: UITableView, viewForFooterInSection _: Int) -> UIView? {
        dividerView()
    }

    func tableView(_: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        section == Sections.main.rawValue ? 1 : 0
    }
}

// MARK: - Folders functionality
extension MyMenuViewController {
    private func fetchFolders() {
        Task {
            do {
                let folders = try await foldersManager.fetchFolders(isForceReload: false, for: appContext.user)
                handleNewFolders(with: folders)
            } catch {
                handleError(with: error)
            }
        }
    }

    private func handleNewFolders(with folders: [FolderViewModel]) {
        hideSpinner()
        let separator = FolderViewModel(name: "", path: "", image: nil, itemType: .separator, backgroundColor: nil, isHidden: nil)
        let standardFolders = folders
            .filter { GeneralConstants.Gmail.standardGmailPaths.contains($0.path) }
            .sorted(by: { left, _ in
                if left.path.caseInsensitiveCompare(Constants.inbox) == .orderedSame {
                    return true
                }
                return false
            })
        let notStandardFolders = folders
            .filter { !GeneralConstants.Gmail.standardGmailPaths.contains($0.path) }
            .filter { $0.isHidden == false }
            .sorted { left, right in
                return left.name < right.name
            }
        var updatedFolders = standardFolders + [separator]
        if notStandardFolders.isNotEmpty {
            updatedFolders += notStandardFolders + [separator]
        }
        // Only reload table node when folder items changed
        if updatedFolders != self.folders {
            self.folders = updatedFolders
            tableNode.reloadData()
        }
    }

    private func handleError(with error: Error) {
        switch AppErr(error) {
        case .connection:
            hideSpinner()
        default:
            showAlert(error: error, message: "error_fetch_folders".localized)
        }
    }
}

// MARK: - Account functionality
extension MyMenuViewController {
    private func addAccount() {
        let vc = MainNavigationController(rootViewController: SignInViewController(appContext: appContext))
        present(vc, animated: true, completion: nil)
    }

    private func handleAccountTap(with index: Int) {
        guard let account = self.accounts[safe: index] else {
            return
        }

        Task {
            do {
                try await appContext.globalRouter.switchActive(user: account, appContext: appContext)
            } catch {
                showAlert(message: error.localizedDescription)
            }
        }
    }
}

// MARK: - UI
extension MyMenuViewController {
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

    private func node(for section: Sections, row: Int) -> ASCellNode {
        switch (section, state) {
        case (.header, _):
            let headerInput = decorator.header(for: appContext.user, image: state.arrowImage)
            return TextImageNode(input: headerInput) { [weak self] node in
                self?.handleTapOn(header: node)
            }
        case (.main, .accountAdding):
            return InfoCellNode(input: decorator.nodeForAccount(for: accounts[row], index: row))
        case (.main, .folders):
            let folder = folders[safe: row]
            if folder?.itemType == .separator {
                return MenuSeparatorCellNode()
            }
            return InfoCellNode(input: folders[safe: row].map(InfoCellNode.Input.init))
        case (.additional, .accountAdding):
            return InfoCellNode(input: .addAccount)
        case (.additional, .folders):
            let item = serviceItems[safe: row]
                .map(InfoCellNode.Input.init)
            return InfoCellNode(input: item)
        }
    }

    private func dividerView() -> UIView {
        UIView().then {
            let divider = UIView(frame: CGRect(x: 16, y: 0, width: view.frame.width - 16, height: 1))
            $0.addSubview(divider)
            $0.backgroundColor = .clear
            divider.backgroundColor = decorator.dividerColor
        }
    }
}

// MARK: - Actions
extension MyMenuViewController {
    private func handleFolderTap(with folder: FolderViewModel) {
        switch folder.itemType {
        case .folder:
            Task {
                do {
                    let input = InboxViewModel(folder)
                    let viewController = try await InboxViewControllerFactory.make(
                        appContext: appContext,
                        viewModel: input
                    )

                    if let topController = topController(controllerType: InboxViewController.self),
                       topController.path == folder.path {
                        sideMenuController()?.sideMenu?.hideSideMenu()
                        viewController.startRefreshing()
                        return
                    }
                    sideMenuController()?.setContentViewController(viewController)
                } catch {
                    showAlert(message: error.errorMessage)
                }
            }
        case .settings:
            if topController(controllerType: SettingsViewController.self) != nil {
                sideMenuController()?.sideMenu?.hideSideMenu()
                return
            }
            Task {
                showSpinner()
                do {
                    sideMenuController()?.setContentViewController(
                        try await SettingsViewController(appContext: appContext)
                    )
                } catch {
                    showAlert(message: error.errorMessage)
                }
                hideSpinner()
            }
        case .logOut:
            Task {
                do {
                    try await appContext.globalRouter.signOut(appContext: appContext)
                } catch {
                    showAlert(message: error.errorMessage)
                }
            }
        case .separator:
            break
        }
    }

    private func handleTapOn(header: TextImageNode) {
        UIView.animate(
            withDuration: 0.3,
            animations: {
                header.imageNode.view.transform = CGAffineTransform(rotationAngle: .pi)
            },
            completion: { [weak self] _ in
                switch self?.state {
                case .accountAdding: self?.state = .folders
                case .folders: self?.state = .accountAdding
                case .none: break
                }
            }
        )
    }

    private func topController<T: UIViewController>(
        controllerType: T.Type
    ) -> T? {
        if let menuViewController = sideMenuController() as? ENSideMenuNavigationController,
           let topViewController = menuViewController.viewControllers.first as? T {
            return topViewController
        }
        return nil
    }
}

// MARK: - SideMenuViewController
extension MyMenuViewController: SideMenuViewController {
    func didOpen() {
        fetchFolders()
    }
}
