//
//  MailServiceProviderType.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 25.12.2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation
import GoogleSignIn
import GoogleAPIClientForREST

enum MailServiceProviderType {
    case gmail
    case imap
}

// MARK: - MailServiceProvider
// Provider should conform to MailServiceProvider protocol to support all app functionality
// MessageSender - sending messages
// RemoteFoldersProviderType - fetching folders
// MessagesListProvider - fetching list of messages
// MessageProvider - show message
// MessageOperationsProvider - delete, read, etc messages
// MessageSearchProvider - search messages in folder
// BackupProvider - Search for backups

protocol MailServiceProvider: MessageSender,
    RemoteFoldersProviderType,
    MessagesListProvider,
    MessageProvider,
    MessageOperationsProvider,
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

