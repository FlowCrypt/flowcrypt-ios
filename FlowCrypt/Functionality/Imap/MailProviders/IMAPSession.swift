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
    let password: String?
    let oAuth2Token: String

    let authType: AuthType
    let connectionType: ConnectionType
}

extension MCOIMAPSession {
    convenience init(session: IMAPSession) {
        self.init()

        hostname = session.hostname
        port = UInt32(session.port)
        username = session.username
        password = session.password
        oAuth2Token = session.oAuth2Token
        if case .oAuth = session.authType {
            authType = .xoAuth2
        }
        connectionType = MCOConnectionType(session.connectionType)
    }
}
