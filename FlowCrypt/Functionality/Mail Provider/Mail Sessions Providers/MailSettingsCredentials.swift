//
//  ImapNetService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 01/04/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import MailCore

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
