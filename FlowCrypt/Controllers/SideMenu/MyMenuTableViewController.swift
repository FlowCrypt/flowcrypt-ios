//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import UIKit
import RxSwift

final class MyMenuTableViewController: UIViewController {
    private enum Constants {
        static let allMail = "All Mail"
        static let inbox = "Inbox"
        static let cellHeight: CGFloat = 60
    }

    // TODO: Inject as a dependency
    private let foldersProvider: FoldersProvider = DefaultFoldersProvider()
    private let dataManager = DataManager.shared

    @IBOutlet var tableView: UITableView!
    @IBOutlet var lblName: UILabel!
    @IBOutlet var lblEmail: UILabel!

    private var folders: [FolderViewModel] = []
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        fetchFolders()
    }

    private func setupUI() {
         // show first name, save space
        let name = dataManager.currentUser()?.name
            .split(separator: " ")
            .first
            .map(String.init) ?? ""

        let email = dataManager.currentUser()?.email
            .replacingOccurrences(of: "@gmail.com", with: "")

        lblName.text = name
        lblEmail.text = email
    }

    private func fetchFolders() {
        showSpinner()
        foldersProvider.fetchFolders()
            .retryWhenToken()
            .observeOn(MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] folders in
                    self?.handleNewFolders(with: folders)
                },
                onError: { [weak self] error in
                    self?.showAlert(error: error, message: Language.could_not_fetch_folders)
                }
            )
            .disposed(by: disposeBag)
    }

    private func handleNewFolders(with result: FoldersContext) {
        hideSpinner()
        folders = result.folders
            .compactMap(FolderViewModel.init)
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
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return folders.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(ofType: MenuCell.self, at: indexPath)
            .setup(with: folders[indexPath.row])
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let folder = folders[safe: indexPath.row] else { return }
        let input = InboxViewModel(folder)
        let inboxVc = InboxViewController.instance(with: input)
        sideMenuController()?.setContentViewController(inboxVc)
    }
}

final class MenuCell: UITableViewCell {
    @IBOutlet var lblName: UILabel!

    func setup(with viewModel: FolderViewModel) -> Self {
        selectionStyle = .none
        lblName.text = viewModel.name
        return self
    }
}



