//
//  MsgListViewController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 23/12/2019.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit

@MainActor
protocol MsgListViewController {
    var path: String { get }

    func open(message: InboxRenderable, path: String, appContext: AppContextWithUser)

    func getUpdatedIndex(for message: InboxRenderable) -> Int?
    func updateMessage(isRead: Bool, at index: Int)
    func removeMessage(at index: Int)
}

extension MsgListViewController where Self: UIViewController {

    // todo - tom - don't know how to add AppContext into init of protocol/extension
    func open(message: InboxRenderable, path: String, appContext: AppContextWithUser) {
        switch message.wrappedType {
        case .message(let message):
            open(message: message, path: path, appContext: appContext)
        case .thread(let thread):
            open(thread: thread, appContext: appContext)
        }
    }

    // TODO: uncomment in "sent message from draft" feature
    private func open(draft: Message, appContext: AppContextWithUser) {
        Task {
            do {
                let controller = try await ComposeViewController(appContext: appContext)
                controller.update(with: draft)
                navigationController?.pushViewController(controller, animated: true)
            } catch {
                showAlert(message: error.localizedDescription)
            }
        }
    }

    private func open(message: Message, path: String, appContext: AppContextWithUser) {
        let thread = MessageThread(
            identifier: message.threadId,
            snippet: nil,
            path: path,
            messages: [message]
        )
        open(thread: thread, appContext: appContext)
    }

    private func open(thread: MessageThread, appContext: AppContextWithUser) {
        Task {
            do {
                let viewController = try await ThreadDetailsViewController(
                    appContext: appContext,
                    thread: thread
                ) { [weak self] (action, message) in
                    self?.handleMessageOperation(message: message, action: action)
                }
                navigationController?.pushViewController(viewController, animated: true)
            } catch {
                showAlert(message: error.localizedDescription)
            }
        }
    }

    // MARK: Operation
    private func handleMessageOperation(message: InboxRenderable, action: MessageAction) {
        guard let indexToUpdate = getUpdatedIndex(for: message) else {
            return
        }

        switch action {
        case .markAsRead(let isRead):
            updateMessage(isRead: isRead, at: indexToUpdate)
        case .moveToTrash, .permanentlyDelete:
            removeMessage(at: indexToUpdate)
        case .archive, .moveToInbox:
            if path.isEmpty { return } // no need to remove in 'All Mail' folder
            removeMessage(at: indexToUpdate)
        }
    }
}
