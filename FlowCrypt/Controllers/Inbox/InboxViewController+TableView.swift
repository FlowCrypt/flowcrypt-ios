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

                let node = InboxCellNode(input: .init(inboxItem))
                    .then { $0.backgroundColor = .backgroundColor }
                if inboxItem.isSelected {
                    node.toggleCheckBox(forceTrue: true)
                    node.isCellSelected = inboxItem.isSelected
                }
                node.delegate = self
                return node
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
            guard let self, let inboxItem = inboxItem(at: indexPath) else { return }
            perform(action: action, inboxItems: [inboxItem])
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
        logger.logInfo("Try to update inbox item at \(index ?? -1)")
        return index
    }

    func updateMessage(isRead: Bool, at index: Int, resetThreadSelect: Bool = true) {
        guard inboxInput.count > index else { return }

        logger.logInfo("Mark as read \(isRead) at \(index)")

        // Mark wrapped message/thread(all mails in thread) as read/unread
        inboxInput[index].markAsRead(isRead)
        if resetThreadSelect {
            inboxInput[index].isSelected = false
        }
        reloadMessage(index: index)
    }

    func updateMessage(labelsToAdd: [MessageLabel], labelsToRemove: [MessageLabel], at index: Int, resetThreadSelect: Bool = true) {
        guard inboxInput.count > index else { return }

        inboxInput[index].update(labelsToAdd: labelsToAdd, labelsToRemove: labelsToRemove)
        if resetThreadSelect {
            inboxInput[index].isSelected = false
        }
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
                            // Set shouldBeginFetch to true after a 0.5-second delay
                            // to prevent issue which willBeginBatchFetchWith is called right away when view appears
                            self?.shouldBeginFetch = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                self?.shouldBeginFetch = true
                            }
                            self?.handleOperation(inboxItem: inboxItem, action: action, resetThreadSelect: false)
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
    func indexPathForMessage(at index: Int) -> IndexPath {
        let row = shouldShowEmptyView ? index + 1 : index
        return IndexPath(row: row, section: 0)
    }

    private func inboxItem(at indexPath: IndexPath) -> InboxItem? {
        let index = shouldShowEmptyView ? indexPath.row - 1 : indexPath.row
        return inboxInput[safe: index]
    }

    private func permanentlyDelete(inboxItems: [InboxItem]) {
        showPermanentDeleteThreadAlert(threadCount: inboxItems.count, onAction: { [weak self] _ in
            guard let self else { return }
            for inboxItem in inboxItems {
                self.handleOperation(inboxItem: inboxItem, action: .permanentlyDelete)
                Task {
                    try? await self.threadOperationsApiClient.delete(id: inboxItem.threadId)
                }
            }
            updateNavigationBar()
        })
    }

    private func performMessageAction(_ action: MessageAction, inboxItems: [InboxItem]) {
        for inboxItem in inboxItems {
            handleOperation(inboxItem: inboxItem, action: action)
            Task {
                try? await messageActionsHelper.perform(
                    action: action,
                    with: inboxItem,
                    viewController: self,
                    showSpinner: false
                )
            }
        }
        updateNavigationBar()
    }

    func perform(action: MessageAction, inboxItems: [InboxItem]) {
        // For permanently delete, a distinct mechanism is required. An alert must be displayed first,
        // followed by iterating through the selected threads for deletion.
        if action == .permanentlyDelete {
            permanentlyDelete(inboxItems: inboxItems)
        } else {
            performMessageAction(action, inboxItems: inboxItems)
        }
    }

    private func handleOperation(inboxItem: InboxItem, action: MessageAction, resetThreadSelect: Bool = true) {
        hideSpinner()

        guard let indexToUpdate = getUpdatedIndex(for: inboxItem) else {
            // Just reload data when index was not found in rare cases.
            // https://github.com/FlowCrypt/flowcrypt-ios/issues/2366
            state = .refresh
            handleBeginFetching(nil)
            return
        }

        switch action {
        case .markAsRead:
            updateMessage(isRead: true, at: indexToUpdate, resetThreadSelect: resetThreadSelect)
        case .markAsUnread:
            updateMessage(isRead: false, at: indexToUpdate, resetThreadSelect: resetThreadSelect)
        case .moveToTrash, .permanentlyDelete:
            removeMessage(at: indexToUpdate)
        case .archive, .moveToInbox:
            if path == "INBOX" { // Remove messages in inbox folder
                removeMessage(at: indexToUpdate)
            } else {
                updateMessage(
                    labelsToAdd: action == .moveToInbox ? [.inbox] : [],
                    labelsToRemove: action == .archive ? [.inbox] : [],
                    at: indexToUpdate,
                    resetThreadSelect: resetThreadSelect
                )
            }
        }
    }
}

extension InboxViewController: InboxCellNodeDelegate {
    private func updateInboxSelection(row: Int, isSelected: Bool) {
        var adjustedRow = row
        if shouldShowEmptyView { // Adjust the row index for views that show an empty row
            adjustedRow -= 1
        }
        inboxInput[adjustedRow].isSelected = isSelected
    }

    @objc func handleLongPressGesture(_ recognizer: UILongPressGestureRecognizer) {
        guard recognizer.state == .began,
              let indexPath = tableNode.indexPathForRow(at: recognizer.location(in: tableNode.view)),
              let inboxCellNode = tableNode.nodeForRow(at: indexPath) as? InboxCellNode else { return }
        inboxCellNode.isCellSelected.toggle()
        updateInboxSelection(row: indexPath.row, isSelected: inboxCellNode.isCellSelected)
        inboxCellNode.toggleCheckBox()
        updateNavigationBar()
    }

    func inboxCellNodeDidToggleSelection(_ node: InboxCellNode, isSelected: Bool) {
        updateInboxSelection(row: node.indexPath!.row, isSelected: isSelected)
        node.isCellSelected = isSelected
        updateNavigationBar()
    }

    func updateNavigationBar() {
        if inboxInput.contains(where: \.isSelected) {
            setupThreadSelectNavigationBar()
        } else {
            setupNavigationBar()
        }
    }
}
