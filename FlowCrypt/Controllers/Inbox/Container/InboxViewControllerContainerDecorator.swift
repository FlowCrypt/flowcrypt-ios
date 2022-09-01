//
//  InboxViewControllerContainerDecorator.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 27.11.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptUI
import UIKit

struct InboxViewControllerContainerDecorator {
    func emptyFoldersInput(with size: CGSize) -> TextCellNode.Input {
        TextCellNode.Input(
            backgroundColor: .backgroundColor,
            title: "error_no_folders".localized,
            withSpinner: false,
            size: size
        )
    }

    func errorInput(with size: CGSize, error: Error) -> TextCellNode.Input {
        TextCellNode.Input(
            backgroundColor: .backgroundColor,
            title: "error_general_text".localized + "\n\n\(error.errorMessage)",
            withSpinner: false,
            size: size,
            insets: .deviceSpecificTextInsets(top: 8, bottom: 8)
        )
    }

    func retryActionTitle() -> NSAttributedString {
        "retry_title".localized.attributed(color: .white)
    }
}
