//
//  Imap+session.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 9/11/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Promises

enum ConnectionType {
    case tls
}

enum AuthType {
    case oAuth2
}

struct IMAPSession {
    let hostname: String
    let port: Int
    let username: String
    let password: String?
    let oAuth2Token: String

    let authType: AuthType
    let connectionType: ConnectionType
}

struct SMTPSession {
    let hostname: String
    let port: Int
    let username: String
    let password: String?
    let oAuth2Token: String

    let authType: AuthType
    let connectionType: ConnectionType
}

extension DataService {
    func imapSession() -> IMAPSession {
        guard let username = email, let accessToken = currentToken else {
            fatalError("Can't get IMAP Session without user data")
        }

        return IMAPSession(
            hostname: "imap.gmail.com",
            port: 993,
            username: username,
            password: nil,
            oAuth2Token: accessToken,
            authType: .oAuth2,
            connectionType: .tls
        )
    }

    func smtpSession() -> SMTPSession {
        guard let username = email, let accessToken = currentToken else {
            fatalError("Can't get SMTP Session without user data")
        }

        return SMTPSession(
            hostname: "smtp.gmail.com",
            port: 465,
            username: username,
            password: nil,
            oAuth2Token: accessToken,
            authType: .oAuth2,
            connectionType: .tls
        )
    }
}

extension MCOIMAPSession {
    convenience init(session: IMAPSession) {
        self.init()

        hostname = session.hostname
        port = UInt32(session.port)
        username = session.username
        password = session.password
        oAuth2Token = session.oAuth2Token
        authType = {
            switch session.authType {
            case .oAuth2: return .xoAuth2
            }
        }()
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
        authType = {
            switch session.authType {
            case .oAuth2: return .xoAuth2
            }
        }()
        connectionType = {
            switch session.connectionType {
            case .tls: return .TLS
            }
        }()
    }
}


extension Imap {
    func createNewConnection(imapSession: IMAPSession?, smtpSession: SMTPSession?) {
        if let imap = imapSession {
            debugPrint("IMAP: creating a new session")
            let newImapSession = MCOIMAPSession(session: imap)
            logConnection(for: newImapSession)
            imapSess = newImapSession
        }

        if let smtp = smtpSession {
            debugPrint("SMTP: creating a new session")
            let newSmtpSession = MCOSMTPSession(session: smtp)
            smtpSess = newSmtpSession
        }
    }

//    @discardableResult
//    func getImapSess(newAccessToken: String? = nil) -> MCOIMAPSession {
//        if let existingImapSess = imapSess, newAccessToken == nil {
//            return existingImapSess
//        }
//        debugPrint("IMAP: creating a new session")
//
//        let newImapSess = MCOIMAPSession(session: dataService.imapSession())
//
//        // logImap(session: newImapSess)
//
//        imapSess = newImapSess
//
//        return newImapSess
//    }

    private func logConnection(for session: MCOIMAPSession) {
        session.connectionLogger = {(connectionID, type, data) in
            guard let data = data, let string = String(data: data, encoding: .utf8) else { return }
            debugPrint("IMAP:\(type):\(string)")
        }
    }

//    @discardableResult
//    func getSmtpSess(newAccessToken: String? = nil) -> MCOSMTPSession {
//        if let existingSess = smtpSess, newAccessToken == nil {
//            return existingSess
//        }
//        debugPrint("SMTP: creating a new session")
//
//        let newSmtpSess = MCOSMTPSession()
//
//        newSmtpSess.username = email
//        newSmtpSess.password = nil
//        newSmtpSess.oAuth2Token = newAccessToken ?? accessToken ?? "(no access token)"
//        smtpSess = newSmtpSess
//        return newSmtpSess
//    }

    @discardableResult
    func renewSession() -> Promise<Void> {
        return userService
            .renewAccessToken()
            .then { [weak self] token -> Void in
                self?.handleNewAccessToken()
            }
    }

    private func handleNewAccessToken() {
        createNewConnection(
            imapSession: dataService.imapSession(),
            smtpSession: dataService.smtpSession()
        )
    }

    func disconnect() {
        let start = DispatchTime.now()
        imapSess?.disconnectOperation().start { error in log("disconnect", error: error, res: nil, start: start) }
        imapSess = nil
        smtpSess = nil // smtp session has no disconnect method
    }
}
