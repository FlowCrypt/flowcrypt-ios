//
//  MessageHandlerViewConroller.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 23/12/2019.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit

protocol MsgListViewController {
    func open(with message: InboxRenderable, path: String)

    func getUpdatedIndex(for message: InboxRenderable) -> Int?
    func updateMessage(isRead: Bool, at index: Int)
    func removeMessage(at index: Int)
}

extension MsgListViewController where Self: UIViewController {
    func open(with message: InboxRenderable, path: String) {
        switch message.wrappedType {
        case .message(let message):
            openMsgElseShowToast(with: message, path: path)
        case .thread(let thread):
            openThread(with: thread)
        }
    }

    // TODO: uncomment in "sent message from draft" feature
    private func openDraft(with message: Message) {
        guard let email = DataService.shared.email else { return }

        let controller = ComposeViewController(email: email)
        controller.updateWithMessage(message: message)
        navigationController?.pushViewController(controller, animated: true)
    }

    private func openMsgElseShowToast(with message: Message, path: String) {
        if message.size ?? 0 > GeneralConstants.Global.messageSizeLimit {
            showToast("Messages larger than 5MB are not supported yet")
        } else {
            let messageInput = MessageViewController.Input(
                objMessage: message,
                bodyMessage: nil,
                path: path
            )
            let msgVc = MessageViewController(input: messageInput) { [weak self] (action, message) in
                self?.handleMessageOperation(with: message, action: action)
            }
            navigationController?.pushViewController(msgVc, animated: true)
        }
    }

    private func openThread(with thread: MessageThread) {
        guard !thread.messages.contains(where: { ($0.size ?? 0) > GeneralConstants.Global.messageSizeLimit }) else {
            showToast("Messages larger than 5MB are not supported yet")
            return
        }
        
        guard let threadOperationsProvider = MailProvider.shared.threadOperationsProvider else {
            assertionFailure("Internal error. Provider should conform to MessagesThreadOperationsProvider")
            return
        }
        let viewController = ThreadDetailsViewController(
            threadOperationsProvider: threadOperationsProvider,
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
