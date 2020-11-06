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
    private var authType: AuthType {
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
        switch authType {
        case .gmail: return gmailService
        case .password: return imap
        }
    }

    var remoteFoldersProvider: RemoteFoldersProviderType {
        switch authType {
        case .gmail: return gmailService
        case .password: return imap
        }
    }
}
