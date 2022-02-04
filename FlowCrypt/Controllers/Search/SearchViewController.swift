//
//  SearchViewController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 23/12/2019.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptCommon
import FlowCryptUI
import UIKit

/**
 * View controller to search messages in folders
 * - User can be redirected here from *InboxViewController* by tapping on search icon
 */
final class SearchViewController: TableNodeViewController {
    private lazy var logger = Logger.nested(Self.self)
    private enum Constants {
        // TODO: - Ticket - Add pagination for SearchViewController
        static let messageCount = 100
    }
    enum State {
        enum FetchedUpdates {
            case added(Int), removed(Int)
        }

        case idle, startFetching, empty, fetched([Message], FetchedUpdates?), error(String)

        var messages: [Message] {
            guard case let .fetched(messages, _) = self else { return [] }
            return messages
        }
    }

    private var state: State = .idle {
        didSet { updateState() }
    }

    // TODO: - https://github.com/FlowCrypt/flowcrypt-ios/issues/669 Adopt to gmail threads
    private let service: ServiceActor
    private var searchTask: DispatchWorkItem?
    private let appContext: AppContext
    private let searchController = UISearchController(searchResultsController: nil)
    private let folderPath: String
    private var searchedExpression: String = ""
    private let currentUser: User

    init(
        appContext: AppContext,
        searchProvider: MessageSearchProvider? = nil,
        folderPath: String
    ) {
        guard let currentUser = appContext.dataService.currentUser else {
            fatalError("no current user") // todo - use DI
        }
        self.currentUser = currentUser
        self.appContext = appContext
        self.service = ServiceActor(
            searchProvider: searchProvider ?? appContext.getRequiredMailProvider().messageSearchProvider
        )
        self.folderPath = folderPath
        super.init(node: TableNode())
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
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
        view.backgroundColor = .backgroundColor
        view.accessibilityIdentifier = "searchViewController"

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
            $0.searchBar.setImage(#imageLiteral(resourceName: "search_icn").tinted(.white), for: .search, state: .normal)
            $0.searchBar.setImage(#imageLiteral(resourceName: "cancel").tinted(.white), for: .clear, state: .normal)
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
extension SearchViewController: MsgListViewController {

    func getUpdatedIndex(for message: InboxRenderable) -> Int? {
        guard let message = message.wrappedMessage else {
            return nil
        }
        return state.messages.firstIndex(of: message)
    }

    func updateMessage(isRead: Bool, at index: Int) {
        guard let messageToUpdate = state.messages[safe: index] else {
            return
        }
        logger.logInfo("Mark as read \(isRead) at \(index)")
        var updatedMessages = state.messages
        updatedMessages[safe: index] = messageToUpdate.markAsRead(isRead)
        state = .fetched(updatedMessages, .added(index))
    }

    func removeMessage(at index: Int) {
        var updatedMessages = state.messages
        guard updatedMessages[safe: index] != nil else { return }
        updatedMessages.remove(at: index)
        state = updatedMessages.isEmpty
            ? .empty
            : .fetched(updatedMessages, .removed(index))
    }
}

// MARK: - ASTableDataSource, ASTableDelegate

extension SearchViewController: ASTableDataSource, ASTableDelegate {
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
                    input: TextCellNode.Input(
                        backgroundColor: .backgroundColor,
                        title: "search_empty".localized,
                        withSpinner: false,
                        size: size
                    )
                )
            case .startFetching:
                return TextCellNode(
                    input: TextCellNode.Input(
                        backgroundColor: .backgroundColor,
                        title: "",
                        withSpinner: true,
                        size: size
                    )
                )
            case .idle:
                return TextCellNode(
                    input: TextCellNode.Input(
                        backgroundColor: .backgroundColor,
                        title: "",
                        withSpinner: false,
                        size: size
                    )
                )
            case .fetched:
                return InboxCellNode(
                    input: .init((InboxRenderable(message: self.state.messages[indexPath.row])))
                )
                    .then { $0.backgroundColor = .backgroundColor }
            case let .error(message):
                return TextCellNode(
                    input: TextCellNode.Input(
                        backgroundColor: .backgroundColor,
                        title: message,
                        withSpinner: false,
                        size: size
                    )
                )
            }
        }
    }

    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        tableNode.deselectRow(at: indexPath, animated: false)
        guard let message = state.messages[safe: indexPath.row] else { return }

        // TODO: - https://github.com/FlowCrypt/flowcrypt-ios/issues/669 - cleanup
        open(with: .init(message: message), path: folderPath, appContext: appContext)
    }
}

// MARK: - UISearchControllerDelegate

extension SearchViewController: UISearchControllerDelegate, UISearchBarDelegate {
    func searchBarSearchButtonClicked(_: UISearchBar) {
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

    func didDismissSearchController(_ searchController: UISearchController) {
        searchController.searchBar.text = searchedExpression
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
        searchController.searchBar.searchTextField.accessibilityIdentifier = "searchAllEmailField"
    }
}

// MARK: - UISearchResultsUpdating

extension SearchViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard searchController.isActive else {
            searchTask?.cancel()
            return
        }
        guard let searchText = searchText(for: searchController.searchBar) else {
            searchTask?.cancel()
            state = .idle
            return
        }
        guard searchedExpression != searchText else {
            return
        }

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
        return text
    }

    private func search(for searchText: String) {
        state = .startFetching
        searchedExpression = searchText

        Task {
            do {
                let messages = try await service.searchExpression(
                    using: MessageSearchContext(
                        expression: searchText,
                        count: Constants.messageCount
                    )
                )
                handleProcessedMessage(with: messages)
            } catch {
                handleError(with: error)
            }
        }
    }

    private func handleProcessedMessage(with messages: [Message]) {
        if messages.isEmpty {
            state = .empty
        } else {
            state = .fetched(messages, nil)
        }
    }

    private func handleError(with _: Error) {
        state = .error("search_empty".localized)
    }

    private func updateState() {
        switch state {
        case .empty, .error:
            searchController.dismiss(animated: true, completion: nil)
            node.reloadData()
            node.bounces = false
        case .fetched(_, nil):
            searchController.dismiss(animated: true, completion: nil)
            node.reloadData()
            node.bounces = true
        case let .fetched(_, .added(index)):
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                self?.node.reloadRows(at: [IndexPath(row: index, section: 0)], with: .fade)
            }
        case let .fetched(_, .removed(index)):
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                self?.node.deleteRows(at: [IndexPath(row: index, section: 0)], with: .left)
            }
        case .startFetching, .idle:
            node.reloadData()
            node.bounces = false
        }
    }
}

// TODO temporary solution for background execution problem
private actor ServiceActor {
    private let searchProvider: MessageSearchProvider

    init(searchProvider: MessageSearchProvider) {
        self.searchProvider = searchProvider
    }

    func searchExpression(using context: MessageSearchContext) async throws -> [Message] {
        return try await searchProvider.searchExpression(using: context)
    }
}
