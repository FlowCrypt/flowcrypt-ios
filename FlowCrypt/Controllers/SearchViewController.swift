//
//  SearchViewController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 23/12/2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit

final class SearchViewController: ASViewController<TableNode> {
    enum State {
        case idle, empty, fetched([MCOIMAPMessage]), error(String)
    }
    
    private let messageProvider: SearchResultsProvider
    private var state: State = .idle
    
    init(
        messageProvider: SearchResultsProvider = Imap()
    ) {
        self.messageProvider = messageProvider
        super.init(node: TableNode())
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
    }
}

extension SearchViewController {
    private func setupUI() {
        view.backgroundColor = .white
        title = "search_title".localized
        node.delegate = self
        node.dataSource = self
    }

    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = NavigationBarItemsView(
            with: [
                NavigationBarItemsView.Input(
                    image: UIImage(named: "help_icn"),
                    action: (self, #selector(handleInfoTap))
                )
            ]
        )
    }
    
    @objc private func handleInfoTap() {
        #warning("ToDo")
        showToast("Email us at human@flowcrypt.com")
    }
}

extension SearchViewController : ASTableDataSource, ASTableDelegate {
    func tableNode(_: ASTableNode, numberOfRowsInSection _: Int) -> Int {
        switch state {
        case .fetched(let messages):
            return messages.count
        default:
            return 1
        }
    }

    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        let height = tableNode.frame.size.height
            - (navigationController?.navigationBar.frame.size.height ?? 0.0)
            - safeAreaWindowInsets.top
            - safeAreaWindowInsets.bottom

        let size = CGSize(width: tableNode.frame.size.width, height: height)
        let text = title ?? ""

        return { [weak self] in
            guard let self = self else { return ASCellNode() }

            switch self.state {
            case .empty:
                return TextCellNode(
                    title: "\(text) is empty",
                    withSpinner: false,
                    size: size
                )
            case .idle:
                return TextCellNode(
                    title: "",
                    withSpinner: true,
                    size: size
                )
            case .fetched(let messages):
                return InboxCellNode(message: InboxCellNodeInput(messages[indexPath.row])
                )
            case let .error(message):
                return TextCellNode(title: message, withSpinner: false, size: size)
            }
        }
    }

    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        tableNode.deselectRow(at: indexPath, animated: true)
        guard case let .fetched(messages) = state,
            let message = messages[safe: indexPath.row]
        else { return }

        openMessageIfPossible(with: message, path: "")
    }
}

extension SearchViewController: MessageHandlerViewConroller {
    func handleMessage(operation: MsgViewController.MessageAction, message: MCOIMAPMessage) {
//        guard let index = messages.firstIndex(of: message) else { return }
//        switch operation {
//        case .markAsRead: markAsRead(message: message, at: index)
//        case .moveToTrash, .archive, .permanentlyDelete: delete(message: message, at: index)
//        }
    }

    private func delete(message _: MCOIMAPMessage, at index: Int) {
//        guard messages[safe: index] != nil else { return }
//        messages.remove(at: index)
//
//        if messages.isEmpty {
//            state = .empty
//            tableNode.reloadData()
//        } else {
//            let total = self.state.total ?? 0
//            let newTotalCount = total - 1
//            state = .fetched(newTotalCount)
//            tableNode.deleteRows(at: [IndexPath(row: index, section: 0)], with: .left)
//        }
    }

    private func markAsRead(message: MCOIMAPMessage, at index: Int) {
//        messages[index] = message
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
//            guard let self = self else { return }
//            self.tableNode.reloadRows(at: [IndexPath(row: index, section: 0)], with: .fade)
//        }
    }
}
