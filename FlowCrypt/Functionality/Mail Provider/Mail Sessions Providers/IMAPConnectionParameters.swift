//
//  IMAPSession.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 31/03/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import MailCore

struct IMAPSession {
    let hostname: String
    let port: Int
    let email: String
    let authType: AuthType
    let connectionType: ConnectionType
}

extension IMAPSession {
    init(user: User) throws {
        guard let imap = user.imap else {
            throw AppErr.general("Can't get IMAP Session without user data")
        }

        guard let auth = user.authType, let connection = ConnectionType(rawValue: imap.connectionType) else {
            throw AppErr.general("Authentication type should be defined on this step")
        }

        self.init(
            hostname: imap.hostname,
            port: imap.port,
            email: user.email,
            authType: auth,
            connectionType: connection
        )
    }
}

extension MCOIMAPSession {
    convenience init(session: IMAPSession) {
        self.init()

        hostname = session.hostname
        port = UInt32(session.port)
        username = session.email
        if let type = MCOConnectionType(session.connectionType) {
            connectionType = type
        }

        switch session.authType {
        case let .oAuthGmail(token):
            authType = .xoAuth2
            oAuth2Token = token
        case let .password(userPassword):
            password = userPassword
        }
    }
}
