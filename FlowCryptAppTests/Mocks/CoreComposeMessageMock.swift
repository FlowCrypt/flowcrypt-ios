//
//  CoreComposeMessageMock.swift
//  FlowCryptAppTests
//
//  Created by Anton Kharchevskyi on 25.07.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import Combine
@testable import FlowCrypt

class CoreComposeMessageMock: CoreComposeMessageType {

    var composeEmailResult: ((SendableMsg, MsgFmt, [String]?) -> (CoreRes.ComposeEmail))!
    func composeEmail(msg: SendableMsg, fmt: MsgFmt, pubKeys: [String]?) async throws -> CoreRes.ComposeEmail {
        return composeEmailResult(msg, fmt, pubKeys)
    }
}
