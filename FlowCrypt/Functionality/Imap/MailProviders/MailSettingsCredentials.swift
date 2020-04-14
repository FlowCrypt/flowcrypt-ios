//
//  ImapNetService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 01/04/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation

struct MailSettingsCredentials {
    let hostName: String?
    let port: Int
    let connectionType: ConnectionType
}

extension MailSettingsCredentials {
    init(_ service: MCONetService) {
        self.hostName = service.hostname
        self.port = Int(service.port)
        self.connectionType = ConnectionType(service.connectionType)
    }
}
