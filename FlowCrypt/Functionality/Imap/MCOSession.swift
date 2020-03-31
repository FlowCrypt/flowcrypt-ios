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
        oAuth2Token = session.oAuth2Token
//        authType = {
//            return [MCOAuthType(rawValue: 0)]
//            switch session.authType {
//            case .oAuth2: return .xoAuth2
//            }
//        }()
        connectionType = {
            switch session.connectionType {
            case .tls: return .TLS
            }
        }()
    }
}

extension MCOSMTPSession {
    convenience init(session: SMTPSession) {
        self.init()

        hostname = session.hostname
        port = UInt32(session.port)
        username = session.username
        password = session.password
        oAuth2Token = session.oAuth2Token
//        authType = {
//            return [MCOAuthType.saslLogin]
//            switch session.authType {
//            case .oAuth2: return .xoAuth2
//            }
//        }()
        connectionType = {
            switch session.connectionType {
            case .tls: return .TLS
            }
        }()
    }
}
