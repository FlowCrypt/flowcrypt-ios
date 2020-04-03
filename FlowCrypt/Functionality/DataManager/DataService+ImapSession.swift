//
//  DataService+ImapSession.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 03/04/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation

protocol ImapSessionProvider {
    func imapSession() -> IMAPSession
    func smtpSession() -> SMTPSession
}

extension DataService: ImapSessionProvider {
    func imapSession() -> IMAPSession {
//        let imap = MailProvidersService().getImapSession(for: "antonflowcrypt@yahoo.com")!
//
//        return IMAPSession(
//            hostname: imap.hostName!,
//            port: imap.port,
//            username: "antonflowcrypt@yahoo.com",
//            password: "flowcryptpassword123",
//            oAuth2Token: "NO ACCESS TOKEN",
//            authType: .xoAuth2,
//            connectionType: imap.connectionType
//        )
//
//
        guard let username = email, let accessToken = currentToken else {
            fatalError("Can't get IMAP Session without user data")
        }

        
        return IMAPSession(
            hostname: "imap.gmail.com",
            port: 993,
            username: username,
            password: nil,
            oAuth2Token: accessToken,
            authType: .oAuth,
            connectionType: .tls
        )
    }

    func smtpSession() -> SMTPSession {
//        let smtp = MailProvidersService().getSmtpSession(for: "antonflowcrypt@yahoo.com")!
//
//        return SMTPSession(
//            hostname: smtp.hostName!,
//            port: smtp.port,
//            username: "antonflowcrypt@yahoo.com",
//            password: "flowcryptpassword123",
//            oAuth2Token: "NO ACCESS TOKEN",
//            authType: .xoAuth2,
//            connectionType: smtp.connectionType
//        )

        guard let username = email, let accessToken = currentToken else {
            fatalError("Can't get SMTP Session without user data")
        }

        return SMTPSession(
            hostname: "smtp.gmail.com",
            port: 465,
            username: username,
            password: nil,
            oAuth2Token: accessToken,
            authType: .oAuth,
            connectionType: .tls
        )
    }
}


