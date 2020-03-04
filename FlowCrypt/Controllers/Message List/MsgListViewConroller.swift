//
//  MessageHandlerViewConroller.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 23/12/2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import UIKit

protocol MsgListViewConroller {
    func msgListOpenMsgElseShowToast(with message: MCOIMAPMessage, path: String)
    func msgListGetIndex(message: MCOIMAPMessage) -> Array<MCOIMAPMessage>.Index?
    func msgListRenderAsRead(message: MCOIMAPMessage, at index: Int)
    func msgListRenderAsRemoved(message _: MCOIMAPMessage, at index: Int)
}

extension MsgListViewConroller where Self: UIViewController {
    func msgListOpenMsgElseShowToast(with message: MCOIMAPMessage, path: String) {
        if Int(message.size) > GeneralConstants.Global.messageSizeLimit {
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

    private func msgListHandleOperation(message: MCOIMAPMessage, operation: MessageViewController.MessageAction) {
        guard let index = self.msgListGetIndex(message: message) else { return }
        switch operation {
        case .markAsRead: self.msgListRenderAsRead(message: message, at: index)
        case .moveToTrash, .archive, .permanentlyDelete: self.msgListRenderAsRemoved(message: message, at: index)
        }
    }

}
