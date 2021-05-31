//
//  CommonNodes.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 31.05.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import FlowCryptUI
import UIKit

extension TextCellNode.Input {
    static func loading(with size: CGSize) -> TextCellNode.Input {
        .init(
            backgroundColor: .backgroundColor,
            title: "loading_title".localized + "...",
            withSpinner: true,
            size: size
        )
    }
}

extension ButtonCellNode.Input {
    static let retry: ButtonCellNode.Input = .init(
        title: "retry_title"
            .localized
            .attributed(.bold(16), color: .white, alignment: .center),
        insets: UIEdgeInsets(top: 16, left: 24, bottom: 8, right: 24),
        color: .main
    )
}
