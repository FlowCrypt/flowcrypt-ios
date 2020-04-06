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

    convenience init(
        name: String,
        email: String,
        imap: SessionObject?,
        smtp: SessionObject?
    ) {
        self.init()
        self.name = name
        self.email = email
        self.imap = imap
        self.smtp = smtp
    }
}

final class SessionObject: Object {
    @objc dynamic var hostname: String = ""
    @objc dynamic var port: Int = 0
    @objc dynamic var username: String = ""
    @objc dynamic var password: String?
    @objc dynamic var oAuth2Token: String?
    @objc dynamic var connectionType: String = ""

    convenience init(
        hostname: String,
        port: Int,
        username: String,
        password: String?,
        oAuth2Token: String?,
        connectionType: String
    ) {
        self.init()
        self.hostname = hostname
        self.port = port
        self.username = username
        self.password = password
        self.oAuth2Token = oAuth2Token
        self.connectionType = connectionType
    }
}
