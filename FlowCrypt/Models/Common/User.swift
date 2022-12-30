//
//  User.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 8/28/19.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

struct User: Codable, Equatable {
    var email: String
    var isActive: Bool
    var name: String {
        didSet {
            imap?.username = name
            smtp?.username = name
        }
    }

    var imap: Session?
    var smtp: Session?

    var password: String? {
        imap?.password
    }

    var session: SessionType? {
        switch authType {
        case let .oAuthGmail(token):
            return .google(email, name: name, token: token)
        case .password:
            return .session(self)
        case .none:
            return nil
        }
    }
}

extension User {
    static func googleUser(name: String, email: String, token: String) -> User {
        User(
            email: email,
            isActive: true,
            name: name,
            imap: Session.googleIMAP(with: token, username: name, email: email),
            smtp: Session.googleSMTP(with: token, username: name, email: email)
        )
    }
}

extension User {
    var authType: AuthType? {
        if let password {
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
        self.imap = userObject.imap.flatMap(Session.init)
        self.smtp = userObject.smtp.flatMap(Session.init)
    }
}

extension User {
    static var empty: User {
        User(
            email: "",
            isActive: true,
            name: "",
            imap: .empty,
            smtp: .empty
        )
    }
}
