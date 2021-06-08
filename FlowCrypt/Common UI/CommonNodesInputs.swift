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

    static let chooseAnotherAccount: ButtonCellNode.Input = .init(
        title: "setup_use_another"
            .localized
            .attributed(
                .regular(15),
                color: UIColor.colorFor(
                    darkStyle: .black,
                    lightStyle: .blueColor
                ),
                alignment: .center
            ),
        insets: .side(8),
        color: .backgroundColor
    )
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
            insets: .init(top: 8, left: 16, bottom: 8, right: 16),
            preferredSize: CGSize(width: 30, height: 30),
            checkBoxInput: CheckBoxNode.Input(
                color: checkboxColor,
                strokeWidth: 2
            )
        )
    }

    static func passPhraseLocally(isSelected: Bool) -> CheckBoxTextNode.Input {
        Self.common(with: "setup_save_pass_locally".localized, isSelected: isSelected)
    }

    static func passPhraseMemory(isSelected: Bool) -> CheckBoxTextNode.Input {
        Self.common(with: "setup_save_pass_in_memory".localized, isSelected: isSelected)
    }
}
