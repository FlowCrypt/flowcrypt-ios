//
//  ThreadDetailsDecorator.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 19.10.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptUI
import UIKit

extension TextImageNode.Input {
    init(threadMessage: ThreadDetailsViewController.Input) {
        let sender = threadMessage.rawMessage.sender ?? "message_unknown_sender".localized
        let date = DateFormatter().formatDate(threadMessage.rawMessage.date)
        // TODO: - ANTON - is read
        let isMessageRead = threadMessage.rawMessage.isMessageRead
        print("^^ \(isMessageRead)")

        let collapseImage = #imageLiteral(resourceName: "arrow_up").tinted(.white)
        let expandImage = #imageLiteral(resourceName: "arrow_down").tinted(.white)
        let image = threadMessage.isExpanded ? expandImage : collapseImage

        let style: NSAttributedString.Style = isMessageRead
            ? .regular(17)
            : .bold(17)

        let dateColor: UIColor = isMessageRead
            ? .lightGray
            : .main

        let textColor: UIColor = isMessageRead
            ? .lightGray
            : .mainTextUnreadColor

        self.init(
            title: NSAttributedString.text(from: sender, style: style, color: textColor),
            subtitle: NSAttributedString.text(from: date, style: style, color: dateColor),
            image: image,
            imageSize: CGSize(width: 16, height: 16),
            nodeInsets: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8),
            backgroundColor: .backgroundColor
        )
    }
}
