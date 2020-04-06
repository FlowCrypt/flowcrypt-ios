//
//  IMAPSession.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 31/03/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation

struct IMAPSession {
    let hostname: String
    let port: Int
    let username: String
    let authType: AuthType
    let connectionType: ConnectionType
}

extension MCOIMAPSession {
    convenience init(session: IMAPSession) {
        self.init()

        hostname = session.hostname
        port = UInt32(session.port)
        username = session.username
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
