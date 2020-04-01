//
//  ImapNetService.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 01/04/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation

struct ImapNetService {
    let hostName: String?
    let port: Int
    let connectionType: MCOConnectionType
}

extension ImapNetService {
    init(_ service: MCONetService) {
        self.hostName = service.hostname
        self.port = Int(service.port)
        self.connectionType = service.connectionType
    }
}
