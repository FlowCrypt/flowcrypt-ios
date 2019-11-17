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
    var subTitleInset: UIEdgeInsets { get }
    var buttonInsets: UIEdgeInsets { get }
    var subtitleStyle: (String) -> NSAttributedString { get }
}

struct ImportKeyDecorator: ImportKeyDecoratorType {
    let sceneTitle = "import_key_title".localized
    let title = "import_key_description".localized.attributed(.bold(35), color: .black, alignment: .center)
    let fileImportTitle = "import_key_file".localized.attributed(.regular(17), color: .white, alignment: .center)
    let pasteBoardTitle = "import_key_paste".localized.attributed(.regular(17), color: .white, alignment: .center)
    let buttonInsets = UIEdgeInsets(top: 32, left: 16, bottom: 16, right: 16)
    let titleInsets = UIEdgeInsets(top: 100, left: 16, bottom: 46, right: 16)
    let subTitleInset = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
    var subtitleStyle: (String) -> NSAttributedString {
        { $0.attributed(.regular(17), alignment: .center) }
    }
}
