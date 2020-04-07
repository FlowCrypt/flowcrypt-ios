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

extension MCOSMTPSession {
    convenience init(session: SMTPSession) {
        self.init()

        hostname = session.hostname
        port = UInt32(session.port)
        username = session.email
        connectionType = MCOConnectionType(session.connectionType)

       switch session.authType {
        case let .oAuth(token):
            authType = .xoAuth2
            oAuth2Token = token
        case let .password(userPassword):
            password = userPassword
        }
    }
}

