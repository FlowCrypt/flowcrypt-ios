//
//  MessageDecorator.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 06.11.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import UIKit

protocol MessageDecoratorType {
    func attributed(title: String) -> NSAttributedString
    func attributed(subject: String) -> NSAttributedString
    func attributed(date: Date?) -> NSAttributedString
    func attributed(text: String?, color: UIColor) -> NSAttributedString
}

struct MessageDecorator: MessageDecoratorType {
    let dateFormatter: DateFormatter

    func attributed(title: String) -> NSAttributedString {
       title.attributed(.regular(15))
    }

    func attributed(subject: String) -> NSAttributedString {
       subject.attributed(.thin(15))
    }

    func attributed(date: Date?) -> NSAttributedString {
        guard let date = date else { return "".attributed(.thin(15)) }
        return dateFormatter.formatDate(date).attributed(.thin(15))
    }

    func attributed(text: String?, color: UIColor) -> NSAttributedString {
        (text ?? "").attributed(.regular(17), color: color)
    }
}
