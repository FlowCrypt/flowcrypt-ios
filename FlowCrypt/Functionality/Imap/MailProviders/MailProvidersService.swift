//
//  MailProviders.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 01/04/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation

protocol MailProvidersType {
    func getImapSession(for email: String) -> ImapNetService?
    func getSmtpSession(for email: String) -> ImapNetService?
}

struct MailProvidersService: MailProvidersType {
    let manager = MCOMailProvidersManager.shared()

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
