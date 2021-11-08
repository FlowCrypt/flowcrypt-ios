//
//  UserMailSessionProvider.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 10.02.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Promises

protocol UsersMailSessionProvider {
    func renewSession() -> Promise<Void>
}
