//
//  ConnectionType.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 03/04/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation

enum AuthType {
    /// gmail authentication with token
    case oAuthGmail(String)
    /// other email provider with password
    case password(String)
}

enum ConnectionType: String, CaseIterable {
    case none, tls, startls
}

extension MCOConnectionType {
    init?(_ connectionType: ConnectionType) {
        switch connectionType {
        case .tls: self = .TLS
        case .startls: self = .startTLS
        case .none: return nil
        }
    }
}

extension ConnectionType {
    init(_ connectionType: MCOConnectionType) {
        switch connectionType {
        case .TLS: self = .tls
        case .startTLS: self = .startls
        default: self = .tls
        }
    }
}
