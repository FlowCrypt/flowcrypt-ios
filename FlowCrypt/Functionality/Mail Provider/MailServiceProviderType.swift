//
//  MailServiceProviderType.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 25.12.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

enum MailServiceProviderType {
    case gmail, imap
}

// MARK: - MailServiceProvider
// Provider should conform to MailServiceProvider protocol to support all app functionality
// RemoteFoldersApiClient - fetching folders
// MessagesListApiClient - fetching list of messages
// MessageProvider - show message
// MessageOperationsApiClient - delete, read, etc messages
// MessageSearchApiClient - search messages in folder
// BackupApiClient - Search for backups

// MARK: Optionally
// MessagesThreadApiClient - Fetch user threads

protocol MailServiceProvider: MessageGateway,
    RemoteFoldersApiClient,
    MessageProvider,
    MessageOperationsApiClient,
    MessageSearchApiClient,
    BackupApiClient,
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
