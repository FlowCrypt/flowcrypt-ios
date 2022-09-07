//
//  GlobalServices.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 04.11.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import GoogleAPIClientForREST_Gmail
import UIKit

// TODO - Instead of get properties use some DI mechanism
// to reuse already initialised services
// and remove them on logout

/// Provides with proper mail services based on current auth type
final class MailProvider {

    private var currentAuthType: AuthType // todo - originally was auto-enclosure, testing

    private var authType: AuthType {
        switch currentAuthType {
        case let .oAuthGmail(token):
            return .oAuthGmail(token)
        case let .password(password):
            return .password(password)
        }
    }
    private let services: [MailServiceProvider]

    var messageSender: MessageGateway {
        get throws {
            try resolveService(of: MessageGateway.self)
        }
    }

    var remoteFoldersProvider: RemoteFoldersProviderType {
        get throws {
            try resolveService(of: RemoteFoldersProviderType.self)
        }
    }

    var remoteSendAsProvider: RemoteSendAsProviderType {
        get throws {
            try resolveService(of: RemoteSendAsProviderType.self)
        }
    }

    var messageListProvider: MessagesListProvider {
        get throws {
            try resolveService(of: MessagesListProvider.self)
        }
    }

    var messageProvider: MessageProvider {
        get throws {
            try resolveService(of: MessageProvider.self)
        }
    }

    var messageOperationsProvider: MessageOperationsProvider {
        get throws {
            try resolveService(of: MessageOperationsProvider.self)
        }
    }

    var messageSearchProvider: MessageSearchProvider {
        get throws {
            try resolveService(of: MessageSearchProvider.self)
        }
    }

    var backupProvider: BackupProvider {
        get throws {
            try resolveService(of: BackupProvider.self)
        }
    }

    var sessionProvider: UsersMailSessionProvider {
        get throws {
            try resolveService(of: UsersMailSessionProvider.self)
        }
    }

    var draftGateway: DraftGateway? {
        get throws {
            resolveOptionalService(of: DraftGateway.self)
        }
    }

    var draftsProvider: DraftsListProvider? {
        get throws {
            resolveOptionalService(of: DraftsListProvider.self)
        }
    }

    var messagesThreadProvider: MessagesThreadProvider {
        get throws {
            try resolveService(of: MessagesThreadProvider.self)
        }
    }

    var threadOperationsProvider: MessagesThreadOperationsProvider {
        get throws {
            try resolveService(of: MessagesThreadOperationsProvider.self)
        }
    }

    init(
        currentAuthType: AuthType,
        currentUser: User,
        delegate: AppDelegateGoogleSessionContainer?
    ) {
        self.currentAuthType = currentAuthType
        self.services = MailServiceProviderFactory.services(user: currentUser, delegate: delegate)
    }

    private func resolveService<T>(of type: T.Type) throws -> T {
        guard let service = services.first(where: {
            $0.mailServiceProviderType == authType.mailServiceProviderType
        }) as? T else {
            throw AppErr.general("Email Provider should support this functionality. Can't resolve dependency for \(type)")
        }
        return service
    }

    private func resolveOptionalService<T>(of type: T.Type) -> T? {
        guard let service = services.first(where: {
            $0.mailServiceProviderType == authType.mailServiceProviderType
        }) as? T else {
            return nil
        }
        return service
    }
}

private struct MailServiceProviderFactory {
    static func services(
        user: User,
        delegate: AppDelegateGoogleSessionContainer?
    ) -> [MailServiceProvider] {
        [
            Imap(user: user),
            GmailService(
                currentUserEmail: user.email,
                gmailUserService: GoogleUserService(
                    currentUserEmail: user.email,
                    appDelegateGoogleSessionContainer: delegate
                )
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
        case .oAuthGmail:
            return .byNextPage(token: token)
        }
    }
}
