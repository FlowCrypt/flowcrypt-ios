//
//  Token.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 25.11.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import RealmSwift

// TODO: - ANTON - remove in https://github.com/FlowCrypt/flowcrypt-ios/issues/284
@available(*, deprecated, message: "Use UserObject instead. Remove in scope of https://github.com/FlowCrypt/flowcrypt-ios/issues/284")
final class EmailAccessToken: Object {
    @objc dynamic var value: String = ""

    convenience init(value: String) {
        self.init()
        self.value = value
    }
}
