//
//  Token.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 25.11.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import RealmSwift

final class Token: Object {
    @objc dynamic var value: String?

    convenience init(value: String?) {
        self.init()
        self.value = value
    }
}
