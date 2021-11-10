//
//  UserRealmObject.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 07/04/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import RealmSwift

final class UserRealmObject: Object {
    @objc dynamic var isActive = true
    @objc dynamic var name: String = "" {
        didSet {
            imap?.username = name
            smtp?.username = name
        }
    }
    @objc dynamic var email: String = ""
    @objc dynamic var imap: SessionRealmObject?
    @objc dynamic var smtp: SessionRealmObject?

    var password: String? {
        imap?.password
    }

    convenience init(
        name: String,
        email: String,
        imap: SessionRealmObject?,
        smtp: SessionRealmObject?
    ) {
        self.init()
        self.name = name
        self.email = email
        self.imap = imap
        self.smtp = smtp
    }

    override class func primaryKey() -> String? {
        "email"
    }

    override var description: String {
        email
    }
}

extension UserRealmObject {
    static func googleUser(name: String, email: String, token: String) -> UserRealmObject {
        UserRealmObject(
            name: name,
            email: email,
            imap: SessionRealmObject.googleIMAP(with: token, username: name, email: email),
            smtp: SessionRealmObject.googleSMTP(with: token, username: name, email: email)
        )
    }
}

extension UserRealmObject {
    var authType: AuthType? {
        if let password = password {
            return .password(password)
        }
        if let token = smtp?.oAuth2Token {
            return .oAuthGmail(token)
        }
        return nil
    }
}

extension User {
    init(_ userObject: UserRealmObject) {
        self.name = userObject.name
        self.email = userObject.email
        self.isActive = userObject.isActive
    }
}

extension UserRealmObject {
    static var empty: UserRealmObject {
        UserRealmObject(
            name: "",
            email: "",
            imap: .empty,
            smtp: .empty
        )
    }
}
