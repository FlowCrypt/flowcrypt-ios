//
//  InboxViewControllerContainer.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 24.11.2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptUI
import FlowCryptCommon

// MARK: - InboxViewControllerContainer
// Used to fetch folders and get correct path for "inbox" folder
final class InboxViewControllerContainer: TableNodeViewController {
    private let inbox = "inbox"

    private enum InboxViewControllerContainerError: Error {
        case noInbox
        case internalError
    }

    private enum State {
        case loading
        case error(Error)
        case empty
        case loadedFolders([FolderViewModel])
    }

    let folderService: FoldersServiceType
    let decorator: InboxViewControllerContainerDecorator

    private var state: State = .loading {
        didSet { handleNewState() }
    }

    init(
        folderService: FoldersServiceType = FoldersService(storage: DataService.shared.storage),
        decorator: InboxViewControllerContainerDecorator = InboxViewControllerContainerDecorator()
    ) {
        self.folderService = folderService
        self.decorator = decorator
        super.init(node: TableNode())
        node.delegate = self
        node.dataSource = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        fetchInboxFolder()
    }

    private func fetchInboxFolder() {
        folderService.fetchFolders()
            .then(on: .main) { [weak self] folders in
                self?.handleFetched(folders: folders)
            }
            .catch(on: .main) { [weak self] error in
                self?.state = .error(error)
            }
    }

    private func handleFetched(folders: [FolderViewModel]) {
        guard folders.isNotEmpty else {
            state = .empty
            return
        }

        let containsInbox = folders
            .map(\.path)
            .containsCaseInsensitive(inbox)

        state = containsInbox
            ? .loadedFolders(folders)
            : .error(InboxViewControllerContainerError.noInbox)
    }

    private func handleNewState() {
        switch state {
        case .loading, .error, .empty:
            node.reloadData()
        case .loadedFolders(let folders):
            let folder = folders
                .first(where: { $0.path.caseInsensitiveCompare(inbox) == .orderedSame })

            guard let inbox = folder else {
                state = .error(InboxViewControllerContainerError.internalError)
                return
            }

            let vc = InboxViewController(InboxViewModel(inbox))
            navigationController?.setViewControllers([vc], animated: false)
        }
    }
}

extension InboxViewControllerContainer: ASTableDelegate, ASTableDataSource {
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        switch state {
        case .empty, .loading:
            return 1
        case .error:
            return 2
        case .loadedFolders:
            return 0
        }
    }

    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        let height = tableNode.frame.size.height
            - (navigationController?.navigationBar.frame.size.height ?? 0.0)
            - safeAreaWindowInsets.top
            - safeAreaWindowInsets.bottom

        let size = CGSize(
            width: tableNode.frame.size.width,
            height: max(height, 0)
        )

        // size - retry button height
        let descriptionSize = CGSize(
            width: tableNode.frame.size.width,
            height: max(height - 100, 0)
        )

        return { [weak self] in
            guard let self = self else { return ASCellNode() }

            // Retry Button
            if indexPath.row == 1 {
                return ButtonCellNode(
                    title: self.decorator.retryActionTitle(),
                    insets: UIEdgeInsets.side(8)
                ) {
                    self.fetchInboxFolder()
                }
            }

            switch self.state {
            case .loading:
                return TextCellNode(
                    input: self.decorator.loadingInput(with: size)
                )
            case .error(let error):
                return TextCellNode(
                    input: self.decorator.errorInput(with: descriptionSize, error: error)
                )
            case .empty:
                return TextCellNode(
                    input: self.decorator.emptyFoldersInput(with: size)
                )
            case .loadedFolders:
                assertionFailure()
                return ASCellNode()
            }
        }
    }
}
