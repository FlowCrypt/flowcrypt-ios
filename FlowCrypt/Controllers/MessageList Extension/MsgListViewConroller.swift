//
//  MessageHandlerViewConroller.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 23/12/2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import UIKit

protocol MsgListViewConroller {
    func msgListOpenMsgElseShowToast(with message: Message, path: String)
    func msgListGetIndex(message: Message) -> Array<Message>.Index?
    func msgListRenderAsRead(message: Message, at index: Int)
    func msgListRenderAsRemoved(message _: Message, at index: Int)
}

extension MsgListViewConroller where Self: UIViewController {
    // TODO: - ANTON - SINGLE MESSAGE - message.size
    func msgListOpenMsgElseShowToast(with message: Message, path: String) {
//        if Int(message.size) > GeneralConstants.Global.messageSizeLimit {
//            showToast("Messages larger than 5MB are not supported yet")
//        } else {
            let messageInput = MessageViewController.Input(
                objMessage: message,
                bodyMessage: nil,
                path: path
            )
            let msgVc = MessageViewController(input: messageInput) { [weak self] operation, message in
                self?.msgListHandleOperation(message: message, operation: operation)
            }
            navigationController?.pushViewController(msgVc, animated: true)
//        }
    }

    private func msgListHandleOperation(message: Message, operation: MessageViewController.MessageAction) {
        guard let index = msgListGetIndex(message: message) else { return }
        switch operation {
        case .markAsRead:
            msgListRenderAsRead(message: message, at: index)
        case .moveToTrash, .archive, .permanentlyDelete:
            msgListRenderAsRemoved(message: message, at: index)
        }
    }
}
