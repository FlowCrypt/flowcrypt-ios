//
//  CommonNodesInputs.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 31.05.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptUI
import UIKit

extension TextCellNode {
    static var loading: TextCellNode {
        .init(
            input: .init(
                backgroundColor: .backgroundColor,
                title: "loading_title".localized + "...",
                withSpinner: true,
                size: CGSize(width: 44, height: 44)
            )
        )
    }
}

extension ButtonCellNode.Input {
    static var retry: ButtonCellNode.Input {
        .init(
            title: "retry_title"
                .localized
                .attributed(.bold(16), color: .white, alignment: .center),
            color: .main
        )
    }

    static var chooseAnotherAccount: ButtonCellNode.Input {
        .init(
            title: "setup_use_another"
                .localized
                .attributed(
                    .regular(15),
                    color: UIColor.colorFor(
                        darkStyle: .white,
                        lightStyle: .blueColor
                    ),
                    alignment: .center
                ),
            color: .backgroundColor
        )
    }
}

extension CheckBoxTextNode.Input {
    static func common(with text: String, isSelected: Bool) -> CheckBoxTextNode.Input {
        let attributedTitle = text
            .attributed(.bold(14), color: .mainTextColor, alignment: .center)

        let checkboxColor: UIColor = isSelected
            ? .main
            : .lightGray

        return CheckBoxTextNode.Input(
            title: attributedTitle,
            insets: .deviceSpecificInsets(top: 8, bottom: 8),
            preferredSize: CGSize(width: 30, height: 30),
            checkBoxInput: CheckBoxNode.Input(
                color: checkboxColor,
                strokeWidth: 2
            )
        )
    }

    static func passPhraseLocally(isSelected: Bool) -> CheckBoxTextNode.Input {
        common(with: "setup_save_pass_locally".localized, isSelected: isSelected)
    }

    static func passPhraseMemory(isSelected: Bool) -> CheckBoxTextNode.Input {
        common(with: "setup_save_pass_temporarily".localized, isSelected: isSelected)
    }
}
