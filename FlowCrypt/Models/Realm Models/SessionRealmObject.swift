//
//  SessionRealmObject.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 07/04/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import RealmSwift

final class SessionRealmObject: Object {
    @Persisted var hostname: String = ""
    @Persisted var port: Int = 0
    @Persisted var username: String = ""
    @Persisted var password: String?
    @Persisted var oAuth2Token: String?
    @Persisted var connectionType: String = ""
    @Persisted var email: String?

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

extension SessionRealmObject {
    static func googleIMAP(with token: String, username: String, email: String) -> SessionRealmObject {
        SessionRealmObject(
            hostname: "imap.gmail.com",
            port: 993,
            username: username,
            password: nil,
            oAuth2Token: token,
            connectionType: ConnectionType.tls.rawValue,
            email: email
        )
    }

    static func googleSMTP(with token: String, username: String, email: String) -> SessionRealmObject {
        SessionRealmObject(
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

extension SessionRealmObject {
    static var empty: SessionRealmObject {
        SessionRealmObject(
            hostname: "",
            port: 0,
            username: "",
            password: nil,
            oAuth2Token: nil,
            connectionType: "",
            email: ""
        )
    }
}
