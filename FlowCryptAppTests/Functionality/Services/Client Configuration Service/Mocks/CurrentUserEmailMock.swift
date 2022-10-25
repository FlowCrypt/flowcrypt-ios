//
//  CurrentUserEmailMock.swift
//  FlowCryptAppTests
//
//  Created by Anton Kharchevskyi on 21.09.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

class CurrentUserEmailMock {
    var currentUserEmailCall: () -> (String?) = {
        nil
    }

    func currentUserEmail() -> String? {
        currentUserEmailCall()
    }
}
