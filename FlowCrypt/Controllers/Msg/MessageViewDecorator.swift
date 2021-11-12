//
//  MessageDecorator.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 06.11.2019.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptUI
import UIKit

extension ProcessedMessage {
    var attributedMessage: NSAttributedString {
        let textColor: UIColor
        switch messageType {
        case .encrypted:
            textColor = .main
        case .error:
            textColor = .red
        case .plain:
            textColor = .mainTextColor
        }
        return text.attributed(color: textColor)
    }
}

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
}

extension AttachmentNode.Input {
    init(msgAttachment: MessageAttachment) {
        self.init(
            name: msgAttachment.name
                .attributed(.regular(18), color: .textColor, alignment: .left),
            size: msgAttachment.humanReadableSizeString
                .attributed(.medium(12), color: .textColor, alignment: .left)
        )
    }
}
