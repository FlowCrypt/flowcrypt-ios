//
//  MenuHeaderViewModel.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 9/13/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import UIKit

struct MenuHeaderViewModel {
    let title: NSAttributedString
    let subtitle: NSAttributedString

    init(title: String, subtitle: String?) {
        self.title = NSAttributedString(
            string: title,
            attributes: [
                NSAttributedString.Key.font : UIFont.systemFont(ofSize: 17, weight: .light),
                NSAttributedString.Key.foregroundColor: UIColor.white
            ]
        )
        self.subtitle = NSAttributedString(
            string: subtitle ?? "",
            attributes: [
                NSAttributedString.Key.font : UIFont.systemFont(ofSize: 11, weight: .light),
                NSAttributedString.Key.foregroundColor: UIColor.white
            ]
        )
    }
}
