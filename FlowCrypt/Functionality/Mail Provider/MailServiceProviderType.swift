//
//  MailServiceProviderType.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 25.12.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import GoogleAPIClientForREST_Gmail

enum MailServiceProviderType {
    case gmail, imap
}

// MARK: - MailServiceProvider
// Provider should conform to MailServiceProvider protocol to support all app functionality
// MessageSender - sending messages
// RemoteFoldersApiClient - fetching folders
// MessagesListApiClient - fetching list of messages
// MessageProvider - show message
// MessageOperationsApiClient - delete, read, etc messages
// MessageSearchProvider - search messages in folder
// BackupProvider - Search for backups

// MARK: Optionally
// MessagesThreadApiClient - Fetch user threads

protocol MailServiceProvider: MessageGateway,
    RemoteFoldersApiClient,
    MessageProvider,
    MessageOperationsApiClient,
    MessageSearchProvider,
    BackupProvider,
    UsersMailSessionProvider {

    var mailServiceProviderType: MailServiceProviderType { get }
}

// MARK: - Convenience
extension AuthType {
    var mailServiceProviderType: MailServiceProviderType {
        switch self {
        case .oAuthGmail: return .gmail
        case .password: return .imap
        }
    }
}
