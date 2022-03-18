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

    private var state: InboxViewController.State = .idle {
        didSet { updateState() }
    }
    private var searchResults: [InboxRenderable] = []

    // TODO: - https://github.com/FlowCrypt/flowcrypt-ios/issues/669 Adopt to gmail threads
    private let service: ServiceActor
    private var searchTask: DispatchWorkItem?
    private let appContext: AppContextWithUser
    private let searchController = UISearchController(searchResultsController: nil)
    private let folderPath: String
    private var searchedExpression: String = ""
    private let decorator: InboxViewDecorator
    private let numberOfInboxItemsToLoad = 100

    init(
        appContext: AppContextWithUser,
        provider: InboxDataProvider,
        folderPath: String
    ) {
        self.appContext = appContext
        self.service = ServiceActor(inboxDataProvider: provider)
        self.folderPath = folderPath
        self.decorator = InboxViewDecorator()
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
        let index = searchResults.firstIndex(where: {
            $0.title == message.title
            && $0.subtitle == message.subtitle
        })
        logger.logInfo("Try to update message at \(String(describing: index))")
        return index
    }

    func updateMessage(isRead: Bool, at index: Int) {
        guard var input = searchResults[safe: index] else {
            return
        }
        logger.logInfo("Mark as read \(isRead) at \(index)")

        input.isRead = isRead
        searchResults[index] = input
        let animationDuration = 0.3
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) { [weak self] in
            self?.node.reloadRows(at: [IndexPath(row: index, section: 0)], with: .fade)
        }
    }

    func removeMessage(at index: Int) {
        guard searchResults[safe: index] != nil else { return }
        logger.logInfo("Try to remove at \(index)")

        searchResults.remove(at: index)

        guard searchResults.isNotEmpty else {
            state = .empty
            return
        }
        switch state {
        case .fetched(.byNumber(let total)):
            let newTotalNumber = (total ?? 0) - 1
            if newTotalNumber == 0 {
                state = .empty
            } else {
                state = .fetched(.byNumber(total: newTotalNumber))
                do {
                    try ObjcException.catch {
                        self.node.deleteRows(at: [IndexPath(row: index, section: 0)], with: .left)
                    }
                } catch {
                    showAlert(message: "Failed to remove message at \(index) in fetched state: \(error)")
                }
            }
        default:
            do {
                try ObjcException.catch {
                    self.node.deleteRows(at: [IndexPath(row: index, section: 0)], with: .left)
                }
            } catch {
                showAlert(message: "Failed to remove message at \(index) in \(state): \(error)")
            }
        }
    }
}

// MARK: - ASTableDataSource, ASTableDelegate

extension SearchViewController: ASTableDataSource, ASTableDelegate {
    func tableNode(_: ASTableNode, numberOfRowsInSection _: Int) -> Int {
        switch state {
        case .empty, .idle, .error, .fetching:
            return 1
        case .fetched, .refresh:
            return searchResults.count
        }
    }

    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        cellNode(for: indexPath, and: visibleSize(for: tableNode))
    }

    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        tableNode.deselectRow(at: indexPath, animated: true)
        open(with: searchResults[indexPath.row], path: folderPath, appContext: appContext)
    }

    private func cellNode(for indexPath: IndexPath, and size: CGSize) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self = self else { return ASCellNode() }

            switch self.state {
            case .empty:
                return TextCellNode(input: self.decorator.emptyStateNodeInput(for: size, title: "search_empty".localized))
            case .idle:
                return TextCellNode(input: self.decorator.initialNodeInput(for: size, withSpinner: false))
            case .fetched, .refresh:
                return InboxCellNode(input: .init((self.searchResults[indexPath.row])))
                    .then { $0.backgroundColor = .backgroundColor }
            case .fetching:
                guard let input = self.searchResults[safe: indexPath.row] else {
                    return TextCellNode.loading
                }
                return InboxCellNode(input: .init(input))
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

    private func currentMessagesListPagination(from number: Int? = nil) -> MessagesListPagination {
        appContext
            .getRequiredMailProvider()
            .currentMessagesListPagination(from: number, token: state.token)
    }
}

// MARK: - Functionality Input
extension SearchViewController {

    private func updateState() {
        switch state {
        case .empty, .error:
            node.reloadData()
            node.bounces = false
        case .fetched:
            node.reloadData()
            node.bounces = true
        case .fetching, .idle:
            node.reloadData()
            node.bounces = false
        default:
            break
        }
    }

    private func handleFetched(_ input: InboxContext) {
        if input.data.isEmpty {
            state = .empty
        } else {
            searchResults.append(contentsOf: input.data)
            state = .fetched(input.pagination)
        }
    }

    private func handle(error: Error) {
        let appError = AppErr(error)
        switch appError {
        case .connection, .general:
            state = .error(appError.errorMessage)
        default:
            showAlert(error: error, message: "message_failed_load".localized)
        }
        node.reloadData()
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
        searchedExpression = searchText
        searchResults = []

        Task {
            do {
                state = .fetching
                let messages = try await service.searchExpression(
                    using: FetchMessageContext(
                        folderPath: self.folderPath,
                        count: numberOfInboxItemsToLoad,
                        searchQuery: "\(searchText) OR subject:\(searchText)",
                        pagination: currentMessagesListPagination()
                    ),
                    userEmail: appContext.user.email
                )
                handleFetched(messages)
            } catch {
                handle(error: error)
            }
        }
    }
}

// TODO temporary solution for background execution problem
private actor ServiceActor {
    private let inboxDataProvider: InboxDataProvider

    init(inboxDataProvider: InboxDataProvider) {
        self.inboxDataProvider = inboxDataProvider
    }

    func searchExpression(using context: FetchMessageContext, userEmail: String) async throws -> InboxContext {
        return try await inboxDataProvider.fetchInboxItems(using: context, userEmail: userEmail)
    }
}
