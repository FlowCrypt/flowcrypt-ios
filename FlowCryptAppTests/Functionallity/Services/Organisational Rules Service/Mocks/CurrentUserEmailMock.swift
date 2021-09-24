//
//  CurrentUserEmailMock.swift
//  FlowCryptAppTests
//
//  Created by Anton Kharchevskyi on 21.09.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
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
