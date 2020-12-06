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
class GlobalServices {
    static var shared: GlobalServices = GlobalServices(currentAuthType: DataService.shared.currentAuthType)

    private var currentAuthType: () -> (AuthType?)
    var authType: AuthType {
        switch currentAuthType() {
        case let .gmail(token):
            return .gmail(token)
        case let .password(password):
            return .password(password)
        default:
            fatalError("Service can't be resolved")
        }
    }

    init(currentAuthType: @autoclosure @escaping () -> (AuthType?)) {
        self.currentAuthType = currentAuthType
    }

    // TODO: - ANTON should be private
    var gmailService: GmailService {
        GmailService(
            signInService: GIDSignIn.sharedInstance(),
            gmailService: GTLRGmailService()
        )
    }

    private var imap: Imap {
        Imap.shared
    }

    var messageSender: MessageSender {
        return imap
        switch authType {
        case .gmail: return gmailService
        case .password: return imap
        }
    }

    var remoteFoldersProvider: RemoteFoldersProviderType {
        return imap
        switch authType {
        case .gmail: return gmailService
        case .password: return imap
        }
    }

    var messageListProvider: MessagesListProvider {
        return imap
        switch authType {
        case .gmail: return gmailService
        case .password: return imap
        }
    }

    var messageProvider: MessageProvider {
        return imap
        switch authType {
        case .gmail: return gmailService
        case .password: return imap
        }
    }
}

// MARK: - Helpers
extension GlobalServices {
    func currentMessagesListPagination(from number: Int? = nil, token: String? = nil) -> MessagesListPagination {
        return .byNumber(total: nil)
        switch authType {
        case .password:
            return MessagesListPagination.byNumber(total: number ?? 0)
        case .gmail:
            return .byNextPage(token: token)
        }
    }
}
