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
    let username: String
    let password: String?
    let oAuth2Token: String

    let authType: AuthType
    let connectionType: ConnectionType
}

extension MCOSMTPSession {
    convenience init(session: SMTPSession) {
        self.init()

        hostname = session.hostname
        port = UInt32(session.port)
        username = session.username
        password = session.password

        if case .oAuth = session.authType {
            authType = .xoAuth2
        }
        connectionType = MCOConnectionType(session.connectionType)
    }
}

