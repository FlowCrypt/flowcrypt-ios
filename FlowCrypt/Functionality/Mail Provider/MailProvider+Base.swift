//
//  MailProvider+Base.swift
//  FlowCrypt
//
//  Created by Evgenii Kyivskyi on 11/9/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import GoogleAPIClientForREST_Gmail

// TODO - Instead of get properties use some DI mechanism
// to reuse already initialised services
// and remove them on logout

/// Provides with proper mail services based on current auth type
final class MailProvider1 {
    static var shared: MailProvider1 = MailProvider1(
        currentAuthType: DataService.shared.currentAuthType,
        services: MailServiceProviderFactory.services()
    )

    private var currentAuthType: () -> (AuthType?)
    private var authType: AuthType {
        switch currentAuthType() {
        case let .oAuthGmail(token):
            return .oAuthGmail(token)
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

    private func resolveService<T>(of type: T.Type) -> T {
        guard let service = services.first(where: { $0.mailServiceProviderType == authType.mailServiceProviderType }) as? T else {
            fatalError("Email Provider should support this functionality")
        }
        return service
    }

    private func resolveOptionalService<T>(of type: T.Type) -> T? {
        guard let service = services.first(where: { $0.mailServiceProviderType == authType.mailServiceProviderType }) as? T else {
            return nil
        }
        return service
    }
}

private struct MailServiceProviderFactory {
    static func services() -> [MailServiceProvider] {
        [
            Imap.shared,
            GmailService()
        ]
    }
}

// MARK: - Helpers
extension MailProvider1 {
    func currentMessagesListPagination(from number: Int? = nil, token: String? = nil) -> MessagesListPagination {
        switch authType {
        case .password:
            return MessagesListPagination.byNumber(total: number ?? 0)
        case .oAuthGmail:
            return .byNextPage(token: token)
        }
    }
}
