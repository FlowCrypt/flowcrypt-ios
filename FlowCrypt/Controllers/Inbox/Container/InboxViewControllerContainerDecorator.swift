//
//  InboxViewControllerContainerDecorator.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 27.11.2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import UIKit
import FlowCryptUI

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
            title: "error_general_text".localized + "\n\n\(error)",
            withSpinner: false,
            size: size
        )
    }

    func retryActionTitle() -> NSAttributedString {
        "retry_title".localized.attributed(color: .white)
    }

    func loadingInput(with size: CGSize) -> TextCellNode.Input {
        TextCellNode.Input(
           backgroundColor: .backgroundColor,
           title: "loading_title".localized,
           withSpinner: true,
           size: size
       )
    }
}
