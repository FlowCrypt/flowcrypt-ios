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
    
    private var state: State = .loading {
        didSet {
            handleNewState()
        }
    }
    
    init(
        folderService: FoldersServiceType = FoldersService(storage: DataService.shared.storage)
    ) {
        self.folderService = folderService
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
                guard folders.isNotEmpty else {
                    self?.state = .empty
                    return
                }
                
                let containsInbox = folders.map(\.path).containsCaseInsensitive("inbox")
                if containsInbox {
                    self?.state = .loadedFolders(folders)
                } else {
                    self?.state = .error(InboxViewControllerContainerError.noInbox)
                }
            }
            .catch(on: .main) { [weak self] error in
                self?.state = .error(error)
            }
    }
    
    private func handleNewState() {
        switch state {
        case .loading:
            node.reloadData()
        case .error(let error):
            print("^^ show error and retry button")
        case .loadedFolders(let folders):
            print("^^ find inbox and load inbox view controller")
//            let vc = InboxViewController(viewModel: nil)
//            sideMenuController()?.setContentViewController(InboxViewController(input))
        
        case .empty:
            print("^^ show some message that there are no folders on account and retry button")
        }
    }
}

extension InboxViewControllerContainer: ASTableDelegate, ASTableDataSource {
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        1
    }
    
    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self = self else { return ASCellNode() }
            return ASCellNode()
        }
    }
}

