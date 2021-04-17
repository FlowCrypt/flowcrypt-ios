//
//  UserObject+Empty.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 13/04/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation

extension UserObject {
    static var empty: UserObject {
        UserObject(
            name: "",
            email: "",
            imap: .empty,
            smtp: .empty
        )
    }
}

extension SessionObject {
    static var empty: SessionObject {
        SessionObject(
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
