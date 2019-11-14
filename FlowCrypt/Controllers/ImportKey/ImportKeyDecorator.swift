//
//  ImportKeyDecorator.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 14.11.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import UIKit

protocol ImportKeyDecoratorType {
    var sceneTitle: String { get }
    var title: NSAttributedString { get }
    var fileImportTitle: NSAttributedString { get }
    var pasteBoardTitle: NSAttributedString { get }
    var titleInsets: UIEdgeInsets { get }
    var buttonInsets: UIEdgeInsets { get }
}

struct ImportKeyDecorator: ImportKeyDecoratorType {
    let sceneTitle = "import_key_title".localized
    let title = "import_key_description".localized.attributed(.bold(35), color: .black, alignment: .center)
    let fileImportTitle = "import_key_file".attributed(.regular(17), color: .white, alignment: .center)
    let pasteBoardTitle = "import_key_paste".attributed(.regular(17), color: .white, alignment: .center)

    // TODO: Anton - refactor
    let titleInsets = SetupDecorator().titleInset
    let buttonInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
}
