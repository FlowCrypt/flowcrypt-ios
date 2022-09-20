//
//  MailProviders.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 01/04/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import MailCore

protocol SessionCredentialsProvider {
    func getImapCredentials(for email: String) -> MailSettingsCredentials?
    func getSmtpCredentials(for email: String) -> MailSettingsCredentials?
    func imapFor(connection: ConnectionType, email: String?) -> Result<MailSettingsCredentials, SessionCredentialsError>
    func smtpFor(connection: ConnectionType, email: String?) -> Result<MailSettingsCredentials, SessionCredentialsError>
}

enum SessionCredentialsError: Error {
    case notFound(Int)
}

struct SessionCredentialsService: SessionCredentialsProvider {

    let manager = MCOMailProvidersManager.shared()
        .then {
            let customProviders = Bundle.main.path(forResource: "providers_custom", ofType: "json")!
            $0.registerProviders(withFilename: customProviders)
        }

    func getImapCredentials(for email: String) -> MailSettingsCredentials? {

        let providers = manager.provider(forEmail: email)

        guard let services = providers?.imapServices() else { return nil }

        // TODO: - check all possible services to establish the connection
        guard let service = services.first else { return nil }

        return MailSettingsCredentials(service)
    }

    func getSmtpCredentials(for email: String) -> MailSettingsCredentials? {
        let providers = manager.provider(forEmail: email)

        guard let services = providers?.smtpServices() else { return nil }

        // TODO: - check all possible services to establish the connection
        guard let service = services.first else { return nil }

        return MailSettingsCredentials(service)
    }

    /// Check are there any imap settings for email and  connection type
    func imapFor(connection: ConnectionType, email: String?) -> Result<MailSettingsCredentials, SessionCredentialsError> {
        func error(for connection: ConnectionType) -> Result<MailSettingsCredentials, SessionCredentialsError> {
            switch connection {
            case .none: return .failure(.notFound(143))
            case .startls: return .failure(.notFound(143))
            case .tls: return .failure(.notFound(993))
            }
        }

        guard
            let email = email,
            let services = manager.provider(forEmail: email)?.imapServices(),
            let credentials = services.first(where: { $0.connectionType == MCOConnectionType(connection) })
        else {
            return error(for: connection)
        }

        return .success(MailSettingsCredentials(credentials))
    }

    /// Check are there any smtp settings for email and  connection type
    func smtpFor(connection: ConnectionType, email: String?) -> Result<MailSettingsCredentials, SessionCredentialsError> {
        func error(for connection: ConnectionType) -> Result<MailSettingsCredentials, SessionCredentialsError> {
            switch connection {
            case .none: return .failure(.notFound(25))
            case .startls: return .failure(.notFound(587))
            case .tls: return .failure(.notFound(465))
            }
        }

        guard
            let email = email,
            let services = manager.provider(forEmail: email)?.smtpServices(),
            let credentials = services.first(where: { $0.connectionType == MCOConnectionType(connection) })
        else {
            return error(for: connection)
        }

        return .success(MailSettingsCredentials(credentials))
    }
}
