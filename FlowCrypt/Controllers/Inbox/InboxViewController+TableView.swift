//
//  InboxViewController+TableView.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 16.12.2022
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptUI

extension InboxViewController: ASTableDataSource, ASTableDelegate {
    func tableNode(_: ASTableNode, numberOfRowsInSection _: Int) -> Int {
        switch state {
        case .empty, .idle, .searchStart, .searching, .searchEmpty, .error:
            return 1
        case .fetched, .refresh, .fetching:
            if shouldShowEmptyView, !inboxInput.isEmpty {
                return inboxInput.count + 1
            }
            return inboxInput.count
        }
    }

    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        cellNode(for: indexPath, and: visibleSize(for: tableNode))
    }

    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        tableNode.deselectRow(at: indexPath, animated: true)
        guard let inboxItem = inboxItem(at: indexPath) else {
            return
        }
        open(inboxItem: inboxItem, path: viewModel.path)
    }

    private func cellNode(for indexPath: IndexPath, and size: CGSize) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self else { return ASCellNode() }

            switch self.state {
            case .empty:
                return EmptyCellNode(
                    input: self.decorator.emptyStateNodeInput(
                        for: size,
                        title: self.inboxTitle,
                        imageName: self.viewModel.path.mailFolderIcon
                    )
                )
            case .searchStart:
                return TextCellNode(input: self.decorator.initialNodeInput(for: size, withSpinner: false))
            case .searchEmpty:
                return TextCellNode(input: self.decorator.searchEmptyStateNodeInput(for: size))
            case .searching:
                return TextCellNode.loading
            case .idle:
                let node = TextCellNode(input: self.decorator.initialNodeInput(for: size))
                node.accessibilityIdentifier = "aid-inbox-idle-node"
                return node
            case .fetched, .refresh:
                if self.shouldShowEmptyView, indexPath.row == 0 {
                    return self.emptyFolderNode()
                }

                guard let inboxItem = self.inboxItem(at: indexPath) else {
                    return TextCellNode.loading
                }

                return InboxCellNode(input: .init(inboxItem))
                    .then { $0.backgroundColor = .backgroundColor }
            case .fetching:
                guard let input = self.inboxInput[safe: indexPath.row] else {
                    return TextCellNode.loading
                }
                return InboxCellNode(input: .init(input))
            case let .error(message):
                return TextCellNode(
                    input: .init(
                        backgroundColor: .backgroundColor,
                        title: message,
                        withSpinner: false,
                        size: size
                    )
                )
            }
        }
    }

    private func emptyFolderNode() -> ASCellNode {
        return EmptyFolderCellNode(
            path: viewModel.path,
            emptyFolder: { [weak self] in
                self?.showConfirmAlert(
                    message: "folder_empty_confirm".localized,
                    onConfirm: { [weak self] _ in
                        self?.emptyInboxFolder()
                    }
                )
            }
        )
    }

    private func emptyInboxFolder() {
        Task {
            do {
                showSpinner()
                try await self.messageOperationsApiClient.emptyFolder(path: viewModel.path)
                self.state = .empty
                self.inboxInput = []
                await tableNode.reloadData()
                hideSpinner()
            } catch {
                showAlert(message: error.errorMessage)
            }
        }
    }

    func tableView(
        _ tableView: UITableView,
        leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        guard let inboxItem = inboxItem(at: indexPath), !inboxItem.isDraft else {
            return nil
        }

        let action = tableSwipeAction(
            for: inboxItem.isInbox ? .archive : .moveToInbox,
            indexPath: indexPath
        )
        return UISwipeActionsConfiguration(actions: [action])
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        guard let inboxItem = inboxItem(at: indexPath) else {
            return nil
        }
        let action = tableSwipeAction(
            for: inboxItem.isTrash ? .permanentlyDelete : .moveToTrash,
            indexPath: indexPath
        )
        return UISwipeActionsConfiguration(actions: [action])
    }

    private func tableSwipeAction(for action: MessageAction, indexPath: IndexPath) -> UIContextualAction {
        let swipeAction = UIContextualAction(style: action.actionStyle, title: nil) { [weak self] _, _, completion in
            self?.perform(action: action, at: indexPath)
            completion(true)
        }
        swipeAction.backgroundColor = action.color
        swipeAction.image = action.image
        return swipeAction
    }
}

extension InboxViewController {
    func getUpdatedIndex(for inboxItem: InboxItem) -> Int? {
        let index = inboxInput.firstIndex(where: {
            $0.title == inboxItem.title && $0.subtitle == inboxItem.subtitle && $0.type == inboxItem.type
        })
        logger.logInfo("Try to update inbox item at \(String(describing: index))")
        return index
    }

    func updateMessage(isRead: Bool, at index: Int) {
        guard inboxInput.count > index else { return }

        logger.logInfo("Mark as read \(isRead) at \(index)")

        // Mark wrapped message/thread(all mails in thread) as read/unread
        inboxInput[index].markAsRead(isRead)
        reloadMessage(index: index)
    }

    func updateMessage(labelsToAdd: [MessageLabel], labelsToRemove: [MessageLabel], at index: Int) {
        guard inboxInput.count > index else { return }

        inboxInput[index].update(labelsToAdd: labelsToAdd, labelsToRemove: labelsToRemove)
        reloadMessage(index: index)
    }

    func reloadMessage(index: Int, animationDuration: Double = 0.3) {
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) { [weak self] in
            guard let self else { return }
            self.tableNode.reloadRows(
                at: [self.indexPathForMessage(at: index)],
                with: .automatic
            )
        }
    }

    func removeMessage(at index: Int) {
        guard inboxInput[safe: index] != nil else { return }

        logger.logInfo("Try to remove at \(index)")
        inboxInput.remove(at: index)

        guard inboxInput.isNotEmpty else {
            state = .empty
            tableNode.reloadData()
            return
        }
        switch state {
        case let .fetched(.byNumber(total)):
            let newTotalNumber = (total ?? 0) - 1
            if newTotalNumber == 0 {
                state = .empty
                tableNode.reloadData()
            } else {
                state = .fetched(.byNumber(total: newTotalNumber))
                do {
                    try ObjcException.catch {
                        self.tableNode.deleteRows(
                            at: [self.indexPathForMessage(at: index)],
                            with: .left
                        )
                    }
                } catch {
                    showAlert(message: "Failed to remove message at \(index) in fetched state: \(error)")
                }
            }
        default:
            do {
                try ObjcException.catch {
                    self.tableNode.deleteRows(
                        at: [self.indexPathForMessage(at: index)],
                        with: .left
                    )
                }
            } catch {
                showAlert(message: "Failed to remove message at \(index) in \(state): \(error)")
            }
        }
    }

    func open(inboxItem: InboxItem, path: String) {
        if inboxItem.isDraft, let draft = inboxItem.messages.first {
            open(draft: draft, appContext: appContext)
        } else {
            Task {
                do {
                    let viewController = try await ThreadDetailsViewController(
                        appContext: appContext,
                        inboxItem: inboxItem,
                        onComposeMessageAction: { [weak self] action in
                            guard let self else { return }

                            switch action {
                            case let .update(identifier), let .sent(identifier), let .delete(identifier):
                                self.fetchUpdatedInboxItem(identifier: identifier)
                            }
                        },
                        onComplete: { [weak self] action, inboxItem in
                            self?.handleOperation(inboxItem: inboxItem, action: action)
                        }
                    )
                    navigationController?.pushViewController(viewController, animated: true)
                } catch {
                    showAlert(message: error.errorMessage)
                }
            }
        }
    }

    private func open(draft: Message, appContext: AppContextWithUser) {
        Task {
            do {
                let draftInfo = ComposeMessageInput.MessageQuoteInfo(
                    message: draft,
                    processed: nil
                )

                let controller = try await ComposeViewController(
                    appContext: appContext,
                    input: .init(type: .draft(draftInfo)),
                    handleAction: { [weak self] action in
                        switch action {
                        case let .update(identifier):
                            self?.fetchUpdatedInboxItem(identifier: identifier)
                        case let .sent(identifier), let .delete(identifier):
                            self?.deleteInboxItem(identifier: identifier)
                        }
                    }
                )
                navigationController?.pushViewController(controller, animated: true)
            } catch {
                showAlert(message: error.errorMessage)
            }
        }
    }

    func fetchUpdatedInboxItem(identifier: MessageIdentifier) {
        guard !inboxInput.isEmpty else {
            fetchAndRenderEmails(nil)
            return
        }

        Task {
            guard let inboxItem = try await inboxDataApiClient.fetchInboxItem(
                identifier: identifier,
                path: path
            ), !inboxItem.messages(with: path).isEmpty else {
                deleteInboxItem(identifier: identifier)
                return
            }

            guard let index = inboxInput.firstIndex(with: identifier) else {
                inboxInput.insert(inboxItem, at: 0)
                tableNode.insertRows(at: [indexPathForMessage(at: 0)], with: .automatic)
                return
            }

            inboxInput[index] = inboxItem
            tableNode.reloadRows(at: [indexPathForMessage(at: index)], with: .automatic)
        }
    }

    private func deleteInboxItem(identifier: MessageIdentifier) {
        guard let index = inboxInput.firstIndex(with: identifier) else { return }

        inboxInput.remove(at: index)

        if inboxInput.isEmpty {
            state = .empty
            tableNode.reloadData()
        } else {
            tableNode.deleteRows(at: [indexPathForMessage(at: index)], with: .automatic)
        }
    }

    // MARK: Operation
    private func indexPathForMessage(at index: Int) -> IndexPath {
        let row = shouldShowEmptyView ? index + 1 : index
        return IndexPath(row: row, section: 0)
    }

    private func inboxItem(at indexPath: IndexPath) -> InboxItem? {
        let index = shouldShowEmptyView ? indexPath.row - 1 : indexPath.row
        return inboxInput[safe: index]
    }

    func perform(action: MessageAction, at indexPath: IndexPath) {
        let inboxIndex = shouldShowEmptyView ? indexPath.row - 1 : indexPath.row
        guard let inboxItem = inboxInput[safe: inboxIndex] else {
            return
        }
        Task {
            do {
                showSpinner()
                try await messageActionsHelper.perform(action: action, with: inboxItem)
                handleOperation(inboxItem: inboxItem, action: action)
            } catch {
                handleOperation(inboxItem: inboxItem, action: action, error: error)
            }
        }
    }

    private func handleOperation(inboxItem: InboxItem, action: MessageAction, error: Error? = nil) {
        hideSpinner()

        if let error {
            logger.logError("\(action.error ?? "Error: ") \(error)")
            showAlert(message: error.errorMessage)
            return
        }

        guard let indexToUpdate = getUpdatedIndex(for: inboxItem) else {
            return
        }

        switch action {
        case .markAsRead:
            updateMessage(isRead: true, at: indexToUpdate)
        case .markAsUnread:
            updateMessage(isRead: false, at: indexToUpdate)
        case .moveToTrash, .permanentlyDelete:
            removeMessage(at: indexToUpdate)
        case .archive, .moveToInbox:
            if path.isEmpty { // no need to remove in 'All Mail' folder
                updateMessage(
                    labelsToAdd: action == .moveToInbox ? [.inbox] : [],
                    labelsToRemove: action == .archive ? [.inbox] : [],
                    at: indexToUpdate
                )
            } else {
                removeMessage(at: indexToUpdate)
            }
        }
    }
}
