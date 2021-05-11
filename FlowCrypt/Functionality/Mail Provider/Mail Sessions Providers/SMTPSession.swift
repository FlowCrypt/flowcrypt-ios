//
//  SMTPSession.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 31/03/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation

struct SMTPSession {
    let hostname: String
    let port: Int
    let email: String
    let authType: AuthType
    let connectionType: ConnectionType
}

extension SMTPSession {
    init?(userObject user: UserObject) {
        guard let smtp = user.smtp else {
            assertionFailure("Can't get SMTP Session without user data")
            return nil
        }

        guard let auth = user.authType, let connection = ConnectionType(rawValue: smtp.connectionType) else {
            assertionFailure("Authentication type should be defined on this step")
            return nil
        }

        self.init(
            hostname: smtp.hostname,
            port: smtp.port,
            email: user.email,
            authType: auth,
            connectionType: connection
        )
    }
}

extension MCOSMTPSession {
    convenience init(session: SMTPSession) {
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
