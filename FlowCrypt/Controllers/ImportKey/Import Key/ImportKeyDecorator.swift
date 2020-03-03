//
//  ImportKeyDecorator.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 14.11.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import UIKit
import FlowCryptUI

protocol ImportKeyDecoratorType {
    var sceneTitle: String { get }
    var title: NSAttributedString { get }
    var fileImportTitle: NSAttributedString { get }
    var pasteBoardTitle: NSAttributedString { get }
    var titleInsets: UIEdgeInsets { get }
    var subTitleInset: UIEdgeInsets { get }
    var buttonInsets: UIEdgeInsets { get }
    var subtitleStyle: (String) -> NSAttributedString { get }

    var passPhraseTitle: NSAttributedString { get }
    var passPhraseContine: NSAttributedString { get }
    var passPhraseChooseAnother: NSAttributedString { get }
    var passPhraseInsets: UIEdgeInsets { get }
    var passPhraseTextFieldStyle: TextFieldCellNode.Input { get }
}

struct ImportKeyDecorator: ImportKeyDecoratorType {
    let sceneTitle = "import_key_title".localized

    var title: NSAttributedString {
        attributed(title: "import_key_description")
    }
    var passPhraseTitle: NSAttributedString {
        attributed(title: "import_key_description")
    }
    var fileImportTitle: NSAttributedString {
        attributed(subTitle: "import_key_file")
    }
    var pasteBoardTitle: NSAttributedString {
        attributed(subTitle: "import_key_paste")
    }
    var passPhraseContine: NSAttributedString {
        attributed(subTitle: "import_key_continue")
    }
    var passPhraseChooseAnother: NSAttributedString {
        attributed(subTitle: "import_key_choose", color: UIColor.white.withAlphaComponent(0.9))
    }

    let buttonInsets = UIEdgeInsets(top: 16, left: 16, bottom: 8, right: 16)
    let passPhraseInsets = UIEdgeInsets(top: 32, left: 16, bottom: 0, right: 16)
    let titleInsets = UIEdgeInsets(top: 100, left: 16, bottom: 30, right: 16)
    let subTitleInset = UIEdgeInsets(top: 8, left: 16, bottom: 16, right: 16)
    var subtitleStyle: (String) -> NSAttributedString {
        { $0.attributed(.regular(17), alignment: .center) }
    }

    private func attributed(title: String) -> NSAttributedString {
        title.localized.attributed(.bold(35), color: .black, alignment: .center)
    }

    private func attributed(subTitle: String, color: UIColor = .white) -> NSAttributedString {
        subTitle.localized.attributed(.regular(17), color: color, alignment: .center)
    }

    let passPhraseTextFieldStyle = SetupCommonStyle.passPhraseTextFieldStyle
}
