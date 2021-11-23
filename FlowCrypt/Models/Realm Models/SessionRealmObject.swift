//
//  SessionRealmObject.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 07/04/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import RealmSwift

final class SessionRealmObject: Object {
    @Persisted var hostname: String
    @Persisted var port: Int
    @Persisted var username: String
    @Persisted var password: String?
    @Persisted var oAuth2Token: String?
    @Persisted var connectionType: String
    @Persisted var email: String?
}

extension SessionRealmObject {
    convenience init(_ session: Session) {
        self.init()
        self.hostname = session.hostname
        self.port = session.port
        self.username = session.username
        self.password = session.password
        self.oAuth2Token = session.oAuth2Token
        self.connectionType = session.connectionType
        self.email = session.email
    }
}
