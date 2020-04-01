//
//  IMAPSession.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 31/03/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation

struct IMAPSession {
    let hostname: String
    let port: Int
    let username: String
    let password: String?
    let oAuth2Token: String

    let authType: MCOAuthType
    let connectionType: MCOConnectionType
}
