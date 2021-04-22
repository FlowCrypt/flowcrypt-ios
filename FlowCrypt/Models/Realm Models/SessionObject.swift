//
//  SessionObject.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 07/04/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation
import RealmSwift

final class SessionObject: Object {
    @objc dynamic var hostname: String = ""
    @objc dynamic var port: Int = 0
    @objc dynamic var username: String = ""
    @objc dynamic var password: String?
    @objc dynamic var oAuth2Token: String?
    @objc dynamic var connectionType: String = ""
    @objc dynamic var email: String?

    convenience init(
        hostname: String,
        port: Int,
        username: String,
        password: String?,
        oAuth2Token: String?,
        connectionType: String,
        email: String
    ) {
        self.init()
        self.hostname = hostname
        self.port = port
        self.username = username
        self.password = password
        self.oAuth2Token = oAuth2Token
        self.connectionType = connectionType
        self.email = email
    }
}

extension SessionObject {
    static func googleIMAP(with token: String, username: String, email: String) -> SessionObject {
        SessionObject(
            hostname: "imap.gmail.com",
            port: 993,
            username: username,
            password: nil,
            oAuth2Token: token,
            connectionType: ConnectionType.tls.rawValue,
            email: email
        )
    }

    static func googleSMTP(with token: String, username: String, email: String) -> SessionObject {
        SessionObject(
            hostname: "smtp.gmail.com",
            port: 465,
            username: username,
            password: nil,
            oAuth2Token: token,
            connectionType: ConnectionType.tls.rawValue,
            email: email
        )
    }
}
