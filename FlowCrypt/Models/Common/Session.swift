//
//  Session.swift
//  FlowCrypt
//
//  Created by  Ivan Ushakov on 16.11.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

struct Session: Codable, Equatable {
    var hostname: String
    var port: Int
    var username: String
    var password: String?
    var oAuth2Token: String?
    var connectionType: String
    var email: String?
}

extension Session {
    static func googleIMAP(with token: String, username: String, email: String) -> Session {
        Session(
            hostname: "imap.gmail.com",
            port: 993,
            username: username,
            password: nil,
            oAuth2Token: token,
            connectionType: ConnectionType.tls.rawValue,
            email: email
        )
    }

    static func googleSMTP(with token: String, username: String, email: String) -> Session {
        Session(
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

extension Session {
    init(_ object: SessionRealmObject) {
        self.hostname = object.hostname
        self.port = object.port
        self.username = object.username
        self.password = object.password
        self.oAuth2Token = object.oAuth2Token
        self.connectionType = object.connectionType
        self.email = object.email
    }
}

extension Session {
    static var empty: Session {
        Session(
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
