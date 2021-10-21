//
//  MessageHandlerViewConroller.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 23/12/2019.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit

protocol MsgListViewController {
    // TODO: - https://github.com/FlowCrypt/flowcrypt-ios/issues/669
    @available(*, deprecated, message: "Remove in favour of .open")
    func msgListOpenMsgElseShowToast(with message: Message, path: String)

    func msgListGetIndex(message: Message) -> Array<Message>.Index?
    func msgListUpdateReadFlag(message: Message, at index: Int)
    func msgListRenderAsRemoved(message _: Message, at index: Int)

    func open(with message: InboxRenderable, path: String)
    func getUpdatedIndex(for message: InboxRenderable) -> Int?
    func updateReadFlag(for index: Int)

}

extension MsgListViewController {
    func updateReadFlag(for index: Int) {

    }

    func getUpdatedIndex(for message: InboxRenderable) -> Int? {
        0
    }
}

extension MsgListViewController where Self: UIViewController {
    func open(with message: InboxRenderable, path: String) {
        switch message.wrappedType {
        case .message(let message):
            msgListOpenMsgElseShowToast(with: message, path: path)
        case .thread(let thread):
            openThread(with: thread)
        }
    }

    // MARK: Message
    func msgListOpenMsgElseShowToast(with message: Message, path: String) {
        tryToOpenMessage(with: message, path: path)
    }

    private func tryToOpenMessage(with message: Message, path: String) {
        if message.size ?? 0 > GeneralConstants.Global.messageSizeLimit {
            showToast("Messages larger than 5MB are not supported yet")
        } else {
            let messageInput = MessageViewController.Input(
                objMessage: message,
                bodyMessage: nil,
                path: path
            )
            let msgVc = MessageViewController(input: messageInput) { [weak self] operation, message in
                self?.msgListHandleOperation(message: message, operation: operation)
            }
            navigationController?.pushViewController(msgVc, animated: true)
        }
    }

    private func msgListHandleOperation(message: Message, operation: MessageAction) {
        guard let index = msgListGetIndex(message: message) else { return }
        switch operation {
        case .changeReadFlag:
            msgListUpdateReadFlag(message: message, at: index)
        case .moveToTrash, .archive, .permanentlyDelete:
            msgListRenderAsRemoved(message: message, at: index)
        }
    }

    // MARK: Thread
    private func openThread(with thread: MessageThread) {
        let viewController = ThreadDetailsViewController(thread: thread) { [weak self] (action, thread) in
            let updatedIndex = self?.getUpdatedIndex(for: InboxRenderable(thread: thread))
            print("^^ \(updatedIndex)")

            // TODO: - ANTON - respond to thread action
            switch action {
            case .changeReadFlag:
                // self?.refresh()
                break
            case .archive:
                break
            case .moveToTrash:
                break
            case .permanentlyDelete:
                break
            }
        }
        navigationController?.pushViewController(viewController, animated: true)
    }
}
