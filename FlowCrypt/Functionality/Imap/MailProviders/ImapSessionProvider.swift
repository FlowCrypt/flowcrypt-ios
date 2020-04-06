//
//  MailProviders.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 01/04/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation

protocol SessionCredentialsProvider {
    func getImapCredentials(for email: String) -> ImapCredentials?
    func getSmtpCredentials(for email: String) -> ImapCredentials?
}

struct ImapSessionService {
    let manager = MCOMailProvidersManager.shared()
}

// MARK: - EmailSessionProvider
extension ImapSessionService: SessionCredentialsProvider {
    func getImapCredentials(for email: String) -> ImapCredentials? {
        let providers = manager?.provider(forEmail: email)

        guard let services = providers?.imapServices() as? [MCONetService] else { return nil }

        // TODO: - check all possible services to establish the connection
        guard let service = services.first else { return nil }

        return ImapCredentials(service)
    }

    func getSmtpCredentials(for email: String) -> ImapCredentials? {
        let providers = manager?.provider(forEmail: email)

        guard let services = providers?.smtpServices() as? [MCONetService] else { return nil }

        // TODO: - check all possible services to establish the connection
        guard let service = services.first else { return nil }

        return ImapCredentials(service)
    }
}
