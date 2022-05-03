//
//  InboxViewControllerContainer.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 24.11.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptCommon
import FlowCryptUI

/**
 * View controller which serves as intermediate controller
 * - Used to fetch folders and get correct path for "inbox" folder
 */
final class InboxViewContainerController: TableNodeViewController {
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

    let appContext: AppContextWithUser
    let foldersService: FoldersServiceType
    let decorator: InboxViewControllerContainerDecorator

    private var state: State = .loading {
        didSet { handleNewState() }
    }

    init(
        appContext: AppContextWithUser,
        foldersService: FoldersServiceType? = nil,
        decorator: InboxViewControllerContainerDecorator = InboxViewControllerContainerDecorator()
    ) {
        self.appContext = appContext
        self.foldersService = foldersService ?? appContext.getFoldersService()
        self.decorator = decorator
        super.init(node: TableNode())
        node.delegate = self
        node.dataSource = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        fetchInboxFolder()
    }

    private func fetchInboxFolder() {
        Task {
            do {
                let folders = try await foldersService.fetchFolders(isForceReload: true, for: appContext.user)
                self.handleFetched(folders: folders)
            } catch {
                self.state = .error(error)
            }
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
        case .loading:
            node.reloadData()
        case .empty:
            showAlert(
                message: "No folders found. Please try again.",
                onOk: { [node] in
                    node?.reloadData()
                }
            )
        case let .error(error):
            showAlert(
                message: error.errorMessage,
                onOk: { [node] in
                    node?.reloadData()
                }
            )
        case .loadedFolders(let folders):
            let folder = folders
                .first(where: { $0.path.caseInsensitiveCompare(inbox) == .orderedSame })

            guard let inbox = folder else {
                state = .error(InboxViewControllerContainerError.internalError)
                return
            }
            let input = InboxViewModel(inbox)
            let inboxViewController = InboxViewControllerFactory.make(
                appContext: appContext,
                viewModel: input
            )
            navigationController?.setViewControllers([inboxViewController], animated: false)
        }
    }
}

extension InboxViewContainerController: ASTableDelegate, ASTableDataSource {
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
                    input: ButtonCellNode.Input(
                        title: self.decorator.retryActionTitle()
                    )
                ) {
                    self.fetchInboxFolder()
                }
            }

            switch self.state {
            case .loading:
                return TextCellNode.loading
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
