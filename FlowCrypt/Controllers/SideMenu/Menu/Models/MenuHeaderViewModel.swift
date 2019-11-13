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
        self.title = title.attributed(.bold(20), color: .white, alignment: .left)
        self.subtitle = (subtitle ?? "").attributed(.medium(16), color: .white, alignment: .left)
    }
}
