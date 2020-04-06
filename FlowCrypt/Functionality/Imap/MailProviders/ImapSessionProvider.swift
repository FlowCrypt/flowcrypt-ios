//
//  MailProviders.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 01/04/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation

protocol EmailSessionProvider {
    func getImapSession(for email: String) -> ImapNetService?
    func getSmtpSession(for email: String) -> ImapNetService?
}

protocol ImapSessionProvider {
    func imapSession() -> IMAPSession
    func smtpSession() -> SMTPSession
}

struct ImapSessionService {
    let manager = MCOMailProvidersManager.shared()
    let dataService: DataServiceType

    init(
        dataService: DataServiceType = DataService.shared
    ) {
        self.dataService = dataService
    }
}

// MARK: - EmailSessionProvider
extension ImapSessionService: EmailSessionProvider {
    func getImapSession(for email: String) -> ImapNetService? {
        let providers = manager?.provider(forEmail: email)

        guard let services = providers?.imapServices() as? [MCONetService] else { return nil }

        // TODO: - check all possible services to establish the connection
        guard let service = services.first else { return nil }

        return ImapNetService(service)
    }

    func getSmtpSession(for email: String) -> ImapNetService? {
        let providers = manager?.provider(forEmail: email)

        guard let services = providers?.smtpServices() as? [MCONetService] else { return nil }

        // TODO: - check all possible services to establish the connection
        guard let service = services.first else { return nil }

        return ImapNetService(service)
    }
}

// MARK: - ImapSessionProvider
extension ImapSessionService: ImapSessionProvider {
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


        guard let username = dataService.email, let accessToken = dataService.currentToken else {
            fatalError("Can't get IMAP Session without user data")
        }

        let imapNetSession = getImapSession(for: username)

//        return IMAPSession(
//            hostname: imapNet!.hostName!,
//            port: imapNet!.port,
//            username: username,
//            password: nil,
//            oAuth2Token: accessToken,
//            authType: .oAuth,
//            connectionType: imapNet!.connectionType
//        )

        return IMAPSession(
            hostname: imapNetSession?.hostName ?? "imap.gmail.com",
            port: imapNetSession?.port ?? 993,
            username: username,
            authType: .oAuth(accessToken),
            connectionType: imapNetSession?.connectionType ?? .tls
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

        guard let username = dataService.email, let accessToken = dataService.currentToken else {
            fatalError("Can't get SMTP Session without user data")
        }

        let smtpNetSession = getSmtpSession(for: username)

        return SMTPSession(
            hostname: smtpNetSession?.hostName ?? "smtp.gmail.com",
            port: smtpNetSession?.port ?? 465,
            username: username,
            authType: .oAuth(accessToken),
            connectionType: smtpNetSession?.connectionType ?? .tls
        )
    }
}
