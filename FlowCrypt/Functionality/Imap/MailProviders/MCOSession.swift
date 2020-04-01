//
//  MCOSession.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 31/03/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation

extension MCOIMAPSession {
    convenience init(session: IMAPSession) {
        self.init()

        hostname = session.hostname
        port = UInt32(session.port)
        username = session.username
        password = session.password
//        oAuth2Token = session.oAuth2Token
        authType = session.authType
        connectionType = session.connectionType
    }
}

extension MCOSMTPSession {
    convenience init(session: SMTPSession) {
        self.init()

        hostname = session.hostname
        port = UInt32(session.port)
        username = session.username
        password = session.password
        authType = session.authType
        connectionType = session.connectionType
    }
}
