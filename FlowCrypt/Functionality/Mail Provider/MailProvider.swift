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

/// Provides with proper mail services based on current auth type
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

    var messageSender: MessageSender {
        resolveService(of: MessageSender.self)
    }

    var remoteFoldersProvider: RemoteFoldersProviderType {
        resolveService(of: RemoteFoldersProviderType.self)
    }

    var messageListProvider: MessagesListProvider {
        resolveService(of: MessagesListProvider.self)
    }

    var messageProvider: MessageProvider {
        resolveService(of: MessageProvider.self)
    }

    var messageOperationsProvider: MessageOperationsProvider {
        resolveService(of: MessageOperationsProvider.self)
    }

    var messageSearchProvider: MessageSearchProvider {
        resolveService(of: MessageSearchProvider.self)
    }

    var backupProvider: BackupProvider {
        resolveService(of: BackupProvider.self)
    }

    private init(
        currentAuthType: @autoclosure @escaping () -> (AuthType?),
        services: [MailServiceProvider]
    ) {
        self.currentAuthType = currentAuthType
        self.services = services
    }

    private func resolveService<T>(of type: T.Type) -> T {
        guard let service = services.first(where: { $0.mailServiceProviderType == authType.mailServiceProviderType }) as? T else {
            fatalError("Email Provider should support this functionality")
        }
        return service
    }
}

private struct MailServiceProviderFactory {
    static func services() -> [MailServiceProvider] {
        [
            Imap.shared,
            GmailService(
                signInService: GIDSignIn.sharedInstance(),
                gmailService: GTLRGmailService()
            )
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
