//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptUI
import Promises

/**
 * Menu view controller
 * Represents User folders and menu buttons like log out and settings
 * User see this screen when taps the burger menu
 * On tap on each folder user should be redirected to `InboxViewController` with selected folder
 * On settings tap user will be redirected to `SettingsViewController`
 */

final class MyMenuViewController: ASDKViewController<ASDisplayNode> {
    private enum Constants {
        static let allMail = "folder_all_mail".localized
        static let inbox = "folder_all_inbox".localized
        static let cellHeight: CGFloat = 60
    }

    private enum Sections: Int, CaseIterable {
        case header = 0, main, additional
    }

    private enum State {
        case folders
        case accountAdding

        mutating func next() {
            switch self {
            case .accountAdding: self = .folders
            case .folders: self = .accountAdding
            }
        }

        var arrowImage: UIImage? {
            switch self {
            case .folders: return #imageLiteral(resourceName: "arrow_down").tinted(.white)
            case .accountAdding: return #imageLiteral(resourceName: "arrow_up").tinted(.white)
            }
        }
    }

    private let foldersProvider: FoldersServiceType
    private let dataService: DataServiceType
    private let router: GlobalRouterType
    private let decorator: MyMenuViewDecoratorType

    private var folders: [FolderViewModel] = []
    private var serviceItems: [FolderViewModel] { FolderViewModel.menuItems }
    private var accounts: [User] { dataService.validAccounts() }

    private let tableNode: ASTableNode

    private var state: State = .folders {
        didSet { tableNode.reloadData() }
    }

    // Due to Bug in ENSideMenu
    // we need to use this property to setup UI in viewDidAppear
    // instead of viewDidload (ENSideMenu call self.view inside initializer)
    private var isFirstLaunch = true

    init(
        foldersProvider: FoldersServiceType = FoldersService(storage: DataService.shared.storage),
        dataService: DataServiceType = DataService.shared,
        globalRouter: GlobalRouterType = GlobalRouter(),
        decorator: MyMenuViewDecoratorType = MyMenuViewDecorator(),
        tableNode: ASTableNode = TableNode()
    ) {
        self.foldersProvider = foldersProvider
        self.dataService = dataService
        self.router = globalRouter
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
        { [weak self] in
            guard let self = self, let section = Sections(rawValue: indexPath.section) else {
                return ASCellNode()
            }
            return self.node(for: section, row: indexPath.row)
        }
    }

    func tableNode(_: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        guard let sections = Sections(rawValue: indexPath.section) else { return }

        switch (sections, state) {
        case (.header, _):
            handleHeaderTap()
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
        showSpinner()
        foldersProvider.fetchFolders(isForceReload: false)
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
}

// MARK: - Account functionality
extension MyMenuViewController {
    private func addAccount() {
        let vc = MainNavigationController(rootViewController: SignInViewController())
        present(vc, animated: true, completion: nil)
    }

    private func handleAccountTap(with index: Int) {
        guard let account = self.accounts[safe: index] else {
            return
        }

        router.switchActive(user: account)
    }

    private func animateImage(_ completion: (() -> Void)?) {
        guard let header = tableNode.visibleNodes.compactMap({ $0 as? HeaderNode }).first else {
            return
        }

        UIView.animate(
            withDuration: 0.3,
            animations: {
                header.imageNode.view.transform = CGAffineTransform(rotationAngle: .pi)
            },
            completion: { _ in
                completion?()
            }
        )
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
            let headerInput = decorator.header(
                for: dataService.currentUser,
                image: state.arrowImage
            )
            return HeaderNode(input: headerInput) { [weak self] in
                self?.handleHeaderTap()
            }
        case (.main, .accountAdding):
            return InfoCellNode(input: decorator.nodeForAccount(for: accounts[row]))
        case (.main, .folders):
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
            let input = InboxViewModel(folder)
            sideMenuController()?.setContentViewController(InboxViewController(input))
        case .settings:
            sideMenuController()?.setContentViewController(SettingsViewController())
        case .logOut:
            router.signOut()
        }
    }

    private func handleHeaderTap() {
        animateImage { [weak self] in
            guard let self = self else {
                return
            }
            switch self.state {
            case .accountAdding: self.state = .folders
            case .folders: self.state = .accountAdding
            }
        }
    }
}

// MARK: - SideMenuViewController
extension MyMenuViewController: SideMenuViewController {
    func didOpen() {
        tableNode.reloadData()
        fetchFolders()
    }
}
