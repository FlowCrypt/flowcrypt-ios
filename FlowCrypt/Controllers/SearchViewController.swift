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
        enum FetchedUpdates {
            case added(Int), removed(Int)
        }
        case idle, startFetching, empty, fetched([MCOIMAPMessage], FetchedUpdates?), error(String)
        
        var messages: [MCOIMAPMessage] {
            guard case let .fetched(messages, _) = self else { return [] }
            return messages
        }
    }
    
    private var state: State = .idle {
        didSet { updateState() }
    }
    
    private let messageProvider: SearchResultsProvider
    private var searchTask: DispatchWorkItem?
    
    private let searchController = UISearchController(searchResultsController: nil)
    private let folderPath: String
    private var searchedExpression: String = ""
    
    init(
        messageProvider: SearchResultsProvider = Imap.shared,
        folderPath: String
    ) {
        self.messageProvider = messageProvider
        self.folderPath = folderPath
        super.init(node: TableNode())
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupSearch()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if case .idle = state {
            searchController.isActive = true
        }
    }
}

// MARK: - Setup

extension SearchViewController {
    private func setupUI() {
        view.backgroundColor = .white
        title = "search_title".localized
        node.delegate = self
        node.dataSource = self
    }

    private func setupSearch() {
        searchController.do {
            $0.delegate = self
            $0.searchResultsUpdater = self
            $0.hidesNavigationBarDuringPresentation = false
            $0.searchBar.tintColor = .white
            $0.searchBar.setImage( #imageLiteral(resourceName: "search_icn").tinted(.white), for: .search, state: .normal)
            $0.searchBar.setImage( #imageLiteral(resourceName: "cancel.png").tinted(.white), for: .clear, state: .normal)
            $0.searchBar.delegate = self
            $0.searchBar.searchTextField.textColor = .white
        }
        update(searchController: searchController)
        definesPresentationContext = true
        navigationItem.titleView = searchController.searchBar
    }
 
    @objc private func handleInfoTap() {
        #warning("ToDo")
        showToast("Email us at human@flowcrypt.com")
    }
}

// MARK: - MessageHandlerViewConroller

extension SearchViewController: MessageHandlerViewConroller {
    func handleMessage(operation: MsgViewController.MessageAction, message: MCOIMAPMessage) {
        guard let index = state.messages.firstIndex(of: message) else { return }
        
        switch operation {
        case .markAsRead:
            markAsRead(message: message, at: index)
        case .moveToTrash, .archive, .permanentlyDelete:
            delete(message: message, at: index)
        }
    }

    private func delete(message _: MCOIMAPMessage, at index: Int) {
        var updatedMessages = state.messages
        guard updatedMessages[safe: index] != nil else { return }
        updatedMessages.remove(at: index)

        if updatedMessages.isEmpty {
            state = .empty
        } else {
            state = .fetched(updatedMessages, .removed(index))
        }
    }

    private func markAsRead(message: MCOIMAPMessage, at index: Int) {
        var updatedMessages = state.messages
        updatedMessages[safe: index] = message
        
        state = .fetched(updatedMessages, .added(index))
    }
}

// MARK: - ASTableDataSource, ASTableDelegate

extension SearchViewController : ASTableDataSource, ASTableDelegate {
    func tableNode(_: ASTableNode, numberOfRowsInSection _: Int) -> Int {
        switch state {
        case .fetched:
            return state.messages.count
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
        return { [weak self] in
            guard let self = self else { return ASCellNode() }

            switch self.state {
            case .empty:
                return TextCellNode(
                    title: "search_empty".localized,
                    withSpinner: false,
                    size: size
                )
            case .startFetching:
                return TextCellNode(
                    title: "",
                    withSpinner: true,
                    size: size
                )
            case .idle:
                return TextCellNode(
                    title: "",
                    withSpinner: false,
                    size: size
                )
            case .fetched:
                return InboxCellNode(
                    message: InboxCellNodeInput(self.state.messages[indexPath.row])
                )
            case let .error(message):
                return TextCellNode(
                    title: message,
                    withSpinner: false,
                    size: size
                )
            }
        }
    }

    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        tableNode.deselectRow(at: indexPath, animated: true)
        guard let message = state.messages[safe: indexPath.row] else { return }

        openMessageIfPossible(with: message, path: folderPath)
    }
}


// MARK: - UISearchControllerDelegate

extension SearchViewController: UISearchControllerDelegate, UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchText = searchText(for: searchController.searchBar) else { return }
        searchTask?.cancel()
        search(for: searchText)
    }
    
    func didPresentSearchController(_ searchController: UISearchController) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.searchController.searchBar.becomeFirstResponder()
        }
        
        update(searchController: searchController)
    }
 
    private func update(searchController: UISearchController) {
        searchController.searchBar.searchTextField.attributedPlaceholder = "search_placeholder"
            .localized
            .attributed(
                .regular(14),
                color: UIColor.white.withAlphaComponent(0.7),
                alignment: .left
            )
        searchController.searchBar.searchTextField.textColor = .white
    }
}

// MARK: - UISearchResultsUpdating

extension SearchViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        defer {
            searchTask?.cancel()
        }
        guard searchController.isActive,
            let searchText = searchText(for: searchController.searchBar)
        else {
            return
        }

        guard searchedExpression != searchText else { return }
        
        searchTask?.cancel()
        let task = DispatchWorkItem { [weak self] in
            self?.search(for: searchText)
        }
        searchTask = task
        
        let throttleTime = 1.0
        DispatchQueue.main.asyncAfter(
            deadline: .now() + throttleTime,
            execute: task
        )
    }
    
    private func searchText(for searchBar: UISearchBar) -> String? {
        guard let text = searchBar.text, text.isNotEmpty else { return nil }
        switch state {
        case .idle, .empty, .error:
            state = .startFetching
        default:
            break
        }
        return text
    }
    
    private func search(for searchText: String) {
        searchedExpression = searchText
        messageProvider.search(
            expression: searchText,
            in: folderPath,
            destinaions: SearchDestinations.allCases,
            count: 10,
            from: 0
            )
            .catch(on: .main) { [weak self] error in
                self?.handleError(with: error)
            }
            .then(on: .main) { [weak self] messages in
                self?.handleFetchedMessages(with: messages)
            }
    }
    
    private func handleFetchedMessages(with messages: [MCOIMAPMessage]) {
        if messages.isEmpty {
            state = .empty
        } else {
            state = .fetched(messages, nil)
        }
    }

    private func handleError(with error: Error) {
        state = .error("search_empty".localized)
    }
    
    private func updateState() {
        switch state {
        case .empty, .error, .fetched(_, nil):
            searchController.dismiss(animated: true, completion: nil)
            node.reloadData()
        case let .fetched(_, .added(index)):
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                self?.node.reloadRows(at: [IndexPath(row: index, section: 0)], with: .fade)
            }
        case let .fetched(_, .removed(index)):
            node.deleteRows(at: [IndexPath(row: index, section: 0)], with: .left)
        case .startFetching:
            node.reloadData()
        case .idle:
            node.reloadData()
        }
    }
}
