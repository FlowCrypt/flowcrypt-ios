//
//  CreatePrivateKeyDecorator.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 23.05.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import FlowCryptCommon
import FlowCryptUI
import UIKit

final class CreatePrivateKeyDecorator {
    let insets = SetupViewInsets()
    let textFieldStyle = SetupCommonStyle.passPhraseTextFieldStyle

    let title = "setup_title"
        .localized
        .attributed(
            .bold(35),
            color: .mainTextColor,
            alignment: .center
        )

    let buttonTitle = "create_pass_phrase_set_title"
        .localized
        .attributed(
            .regular(17),
            color: .white,
            alignment: .center
        )

    let subtitle = "create_pass_phrase_description"
        .localized
        .attributed(.regular(17))

    let optionalDescription = "Lost pass phrase cannot be recovered"
        .localized
        .attributed(
            .regular(16),
            color: .lightGray,
            alignment: .center
        )
}
