//
//  UserObject.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 07/04/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation
import RealmSwift

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

extension UserObject {
    static func googleUser(name: String, email: String, token: String) -> UserObject {
        UserObject(
            name: name,
            email: email,
            imap: SessionObject.googleIMAP(with: token, username: name),
            smtp: SessionObject.googleSMTP(with: token, username: name)
        )
    }
}

extension User {
    init(_ userObject: UserObject) {
        self.name = userObject.name
        self.email = userObject.email
    }
}
