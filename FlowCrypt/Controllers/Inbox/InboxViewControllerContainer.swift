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

import Promises
struct EmptyMock {
    func fetchFolders() -> Promise<[FolderViewModel]> {
        return Promise([])
    }
}

struct ErrorMock {
    enum A: Error {
        case some
    }
    
    func fetchFolders() -> Promise<[FolderViewModel]> {
        return Promise(A.some)
    }
}

final class InboxViewControllerContainer: TableNodeViewController {
    private enum InboxViewControllerContainerError: Error {
        case noInbox
    }

    enum State {
        case loading
        case error(Error)
        case empty
        case loadedFolders([FolderViewModel])
    }

    let folderService: FoldersServiceType
    let decorator: InboxViewControllerContainerDecorator
    
    private var state: State = .loading {
        didSet {
            handleNewState()
        }
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
            .containsCaseInsensitive("inbox")
        
        state = containsInbox
            ? .loadedFolders(folders)
            : .error(InboxViewControllerContainerError.noInbox)
    }

    private func handleNewState() {
        switch state {
        case .loading, .error, .empty:
            node.reloadData()
        case .error:
            node.reloadData()
        case .loadedFolders(let folders):
            print("^^ find inbox and load inbox view controller")
//            let vc = InboxViewController(viewModel: nil)
//            sideMenuController()?.setContentViewController(InboxViewController(input))
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
                    title: self.decorator.retytActionTitle(),
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

struct InboxViewControllerContainerDecorator {
    func emptyFoldersInput(with size: CGSize) -> TextCellNode.Input {
        TextCellNode.Input(
            backgroundColor: .backgroundColor,
            title: "error_no_folders".localized,
            withSpinner: false,
            size: size
        )
    }
    
    func errorInput(with size: CGSize, error: Error) -> TextCellNode.Input {
        TextCellNode.Input(
            backgroundColor: .backgroundColor,
            title: "error_general_text".localized + "\n\n\(error)",
            withSpinner: false,
            size: size
        )
    }
    
    func retytActionTitle() -> NSAttributedString {
        "retry_title".localized.attributed()
    }
    
    func loadingInput(with size: CGSize) -> TextCellNode.Input {
        TextCellNode.Input(
           backgroundColor: .backgroundColor,
           title: "loading_title".localized + "...",
           withSpinner: true,
           size: size
       )
    }
}
