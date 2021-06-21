//
//  MessageDecorator.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 06.11.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import FlowCryptUI
import UIKit

struct MessageViewDecorator {
    let dateFormatter: DateFormatter

    func attributed(title: String) -> NSAttributedString {
        title.attributed(.regular(15), color: .mainTextColor)
    }

    func attributed(subject: String) -> NSAttributedString {
        subject.attributed(.thin(15), color: .mainTextColor)
    }

    func attributed(date: Date?) -> NSAttributedString {
        guard let date = date else { return "".attributed(.thin(15)) }
        return dateFormatter
            .formatDate(date)
            .attributed(.thin(15), color: .mainTextColor)
    }

    func attributed(text: String?, color: UIColor) -> NSAttributedString {
        (text ?? "").attributed(.regular(17), color: color)
    }

    func attributedMessage(from processedMessage: ProcessedMessage) -> NSAttributedString {
        let textColor: UIColor
        switch processedMessage.messageType {
        case .encrypted:
            textColor = .main
        case .error:
            textColor = .red
        case .plain:
            textColor = .mainTextColor
        }
        return processedMessage.text.attributed(color: textColor)
    }
}

extension AttachmentNode.Input {
    init(msgAttachment: MessageAttachment) {
        self.init(
            name: msgAttachment.name
                .attributed(.regular(18), color: .textColor, alignment: .left),
            size: "\(msgAttachment.size)"
                .attributed(.medium(12), color: .textColor, alignment: .left)
        )
    }
}
