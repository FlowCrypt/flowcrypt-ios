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
    func open(with message: InboxRenderable, path: String, appContext: AppContext)

    func getUpdatedIndex(for message: InboxRenderable) -> Int?
    func updateMessage(isRead: Bool, at index: Int)
    func removeMessage(at index: Int)
}

extension MsgListViewController where Self: UIViewController {

    // todo - tom - don't know how to add AppContext into init of protocol/extension
    func open(with message: InboxRenderable, path: String, appContext: AppContext) {
        switch message.wrappedType {
        case .message(let message):
            openMsg(appContext: appContext, with: message, path: path)
        case .thread(let thread):
            openThread(with: thread, appContext: appContext)
        }
    }

    // TODO: uncomment in "sent message from draft" feature
    private func openDraft(appContext: AppContext, with message: Message) {
        let controller = ComposeViewController(appContext: appContext)
        controller.update(with: message)
        navigationController?.pushViewController(controller, animated: true)
    }

    private func openMsg(appContext: AppContext, with message: Message, path: String) {
        let thread = MessageThread(
            identifier: message.threadId,
            snippet: nil,
            path: path,
            messages: [message]
        )
        openThread(with: thread, appContext: appContext)
    }

    private func openThread(with thread: MessageThread, appContext: AppContext) {
        let viewController = ThreadDetailsViewController(
            appContext: appContext,
            thread: thread
        ) { [weak self] (action, message) in
            self?.handleMessageOperation(with: message, action: action)
        }
        navigationController?.pushViewController(viewController, animated: true)
    }

    // MARK: Operation
    private func handleMessageOperation(with message: InboxRenderable, action: MessageAction) {
        guard let indexToUpdate = getUpdatedIndex(for: message) else {
            return
        }

        switch action {
        case .markAsRead(let isRead):
            updateMessage(isRead: isRead, at: indexToUpdate)
        case .archive, .moveToTrash, .permanentlyDelete:
            removeMessage(at: indexToUpdate)
        }
    }
}
