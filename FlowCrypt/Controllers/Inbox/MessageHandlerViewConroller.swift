//
//  MessageHandlerViewConroller.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 23/12/2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import UIKit

protocol MessageHandlerViewConroller {
    func openMessageIfPossible(with message: MCOIMAPMessage, path: String)
    func handleMessage(operation: MsgViewController.MessageAction, message: MCOIMAPMessage)
}

extension MessageHandlerViewConroller where Self: UIViewController {
    func openMessageIfPossible(with message: MCOIMAPMessage, path: String) {
        if Int(message.size) > GeneralConstants.Global.messageSizeLimit {
            showToast("Messages larger than 5MB are not supported yet")
        } else {
            let messageInput = MsgViewController.Input(
                objMessage: message,
                bodyMessage: nil,
                path: path
            )
            
            let msgVc = MsgViewController(input: messageInput) { [weak self] operation, message in
                self?.handleMessage(operation: operation, message: message)
            }
            navigationController?.pushViewController(msgVc, animated: true)
        }
    }
}
