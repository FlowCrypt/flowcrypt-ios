//
//  Helpers.swift
//  FlowCryptUI
//
//  Created by Anton Kharchevskyi on 19/02/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit

public func testAttributedText() -> NSAttributedString {
    let count = Int.random(in: 10 ... 30)
    return NSAttributedString(
        string: String((5 ... count).compactMap { _ in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".randomElement() }),
        attributes: [
            NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14),
            NSAttributedString.Key.foregroundColor: UIColor.black
        ]
    )
}
