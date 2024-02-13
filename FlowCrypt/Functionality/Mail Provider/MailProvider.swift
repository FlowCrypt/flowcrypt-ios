//
//  MailProvider.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 04.11.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

// TODO: - Instead of get properties use some DI mechanism
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

    var messageGateway: MessageGateway {
        get throws {
            try resolveService(of: MessageGateway.self)
        }
    }

    var remoteFoldersApiClient: RemoteFoldersApiClient {
        get throws {
            try resolveService(of: RemoteFoldersApiClient.self)
        }
    }

    var remoteSendAsApiClient: RemoteSendAsApiClient {
        get throws {
            try resolveService(of: RemoteSendAsApiClient.self)
        }
    }

    var messagesListApiClient: MessagesListApiClient {
        get throws {
            try resolveService(of: MessagesListApiClient.self)
        }
    }

    var messageProvider: MessageProvider {
        get throws {
            try resolveService(of: MessageProvider.self)
        }
    }

    var messageOperationsApiClient: MessageOperationsApiClient {
        get throws {
            try resolveService(of: MessageOperationsApiClient.self)
        }
    }

    var messageSearchApiClient: MessageSearchApiClient {
        get throws {
            try resolveService(of: MessageSearchApiClient.self)
        }
    }

    var backupApiClient: BackupApiClient {
        get throws {
            try resolveService(of: BackupApiClient.self)
        }
    }

    var sessionProvider: UsersMailSessionProvider {
        get throws {
            try resolveService(of: UsersMailSessionProvider.self)
        }
    }

    var draftsApiClient: DraftsApiClient? {
        get throws {
            resolveOptionalService(of: DraftsApiClient.self)
        }
    }

    var messagesThreadApiClient: MessagesThreadApiClient {
        get throws {
            try resolveService(of: MessagesThreadApiClient.self)
        }
    }

    var threadOperationsApiClient: MessagesThreadOperationsApiClient {
        get throws {
            try resolveService(of: MessagesThreadOperationsApiClient.self)
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

private enum MailServiceProviderFactory {
    static func services(
        user: User,
        delegate: AppDelegateGoogleSessionContainer?
    ) -> [MailServiceProvider] {
        [
            Imap(user: user),
            GmailService(
                currentUserEmail: user.email,
                googleAuthManager: GoogleAuthManager(
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
