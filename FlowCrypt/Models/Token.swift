//
//  Token.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 25.11.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import RealmSwift

@available(*, deprecated, message: "Use UserObject instead")
final class EmailAccessToken: Object {
    @objc dynamic var value: String = ""

    convenience init(value: String) {
        self.init()
        self.value = value
    }
}


final class UserObject: Object {
    @objc dynamic var name: String = ""
    @objc dynamic var email: String = ""

    @objc dynamic var imap: SessionObject?
    @objc dynamic var smtp: SessionObject?

    var password: String? {
        imap?.password
    }
}

final class SessionObject: Object {
    @objc dynamic var hostname: String = ""
    @objc dynamic var port: Int = 0
    @objc dynamic var username: String = ""
    @objc dynamic var password: String?
    @objc dynamic var oAuth2Token: String?
    @objc dynamic var connectionType: String = ""
}

