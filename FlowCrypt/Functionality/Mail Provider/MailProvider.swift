//
//  GlobalServices.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 04.11.2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation
import GoogleSignIn
import GoogleAPIClientForREST

/// Get proper service based on current auth type
final class MailProvider {
    static var shared: MailProvider = MailProvider(
        currentAuthType: DataService.shared.currentAuthType,
        services: MailServiceProviderFactory.services()
    )

    private var currentAuthType: () -> (AuthType?)
    private var authType: AuthType {
        switch currentAuthType() {
        case let .gmail(token):
            return .gmail(token)
        case let .password(password):
            return .password(password)
        default:
            fatalError("Service can't be resolved. User should be authenticated")
        }
    }

    private let services: [MailServiceProvider]

    private init(
        currentAuthType: @autoclosure @escaping () -> (AuthType?),
        services: [MailServiceProvider]
    ) {
        self.currentAuthType = currentAuthType
        self.services = services
    }

    var messageSender: MessageSender {
        guard let service = services.first(where: { $0.mailServiceProviderType == authType.mailServiceProviderType }) else {
            fatalError("Email Provider should support this functionality")
        }
        return service
    }

    var remoteFoldersProvider: RemoteFoldersProviderType {
        guard let service = services.first(where: { $0.mailServiceProviderType == authType.mailServiceProviderType }) else {
            fatalError("Email Provider should support this functionality")
        }
        return service
    }

    var messageListProvider: MessagesListProvider {
        guard let service = services.first(where: { $0.mailServiceProviderType == authType.mailServiceProviderType }) else {
            fatalError("Email Provider should support this functionality")
        }
        return service
    }

    var messageProvider: MessageProvider {
        guard let service = services.first(where: { $0.mailServiceProviderType == authType.mailServiceProviderType }) else {
            fatalError("Email Provider should support this functionality")
        }
        return service
    }

    var messageOperationsProvider: MessageOperationsProvider {
        guard let service = services.first(where: { $0.mailServiceProviderType == authType.mailServiceProviderType }) else {
            fatalError("Email Provider should support this functionality")
        }
        return service
    }

    var messageSearchProvider: MessageSearchProvider {
        guard let service = services.first(where: { $0.mailServiceProviderType == authType.mailServiceProviderType }) else {
            fatalError("Email Provider should support this functionality")
        }
        return service
    }

    var backupProvider: BackupProvider {
        guard let service = services.first(where: { $0.mailServiceProviderType == authType.mailServiceProviderType }) else {
            fatalError("Email Provider should support this functionality")
        }
        return service
    }
}

struct MailServiceProviderFactory {
    static func services() -> [MailServiceProvider] {
        [
            GmailService(
                signInService: GIDSignIn.sharedInstance(),
                gmailService: GTLRGmailService()
            ),
            Imap.shared
        ]
    }
}

// MARK: - Helpers
extension MailProvider {
    func currentMessagesListPagination(from number: Int? = nil, token: String? = nil) -> MessagesListPagination {
        switch authType {
        case .password:
            return MessagesListPagination.byNumber(total: number ?? 0)
        case .gmail:
            return .byNextPage(token: token)
        }
    }
}
