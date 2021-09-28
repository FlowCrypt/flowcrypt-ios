//
//  LogOutHandler.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 27.02.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

protocol LogOutHandler {
    func logOutUser(email: String) throws
}
