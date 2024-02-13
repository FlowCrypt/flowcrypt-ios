//
//  MsgListViewConroller.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 23/12/2019.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit

protocol MsgListViewConroller {
    func msgListOpenMsg(with message: Message, path: String)
    func msgListGetIndex(message: Message) -> Array<Message>.Index?
    func msgListUpdateReadFlag(message: Message, at index: Int)
    func msgListRenderAsRemoved(message _: Message, at index: Int)
}

extension MsgListViewConroller where Self: UIViewController {
    func msgListOpenMsg(with message: Message, path: String) {
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

    private func msgListHandleOperation(message: Message, operation: MessageViewController.MessageAction) {
        guard let index = msgListGetIndex(message: message) else { return }
        switch operation {
        case .changeReadFlag:
            msgListUpdateReadFlag(message: message, at: index)
        case .moveToTrash, .archive, .permanentlyDelete:
            msgListRenderAsRemoved(message: message, at: index)
        }
    }
}
