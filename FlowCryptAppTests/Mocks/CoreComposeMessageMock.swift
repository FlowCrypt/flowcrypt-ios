//
//  CoreComposeMessageMock.swift
//  FlowCryptAppTests
//
//  Created by Anton Kharchevskyi on 25.07.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import Foundation
@testable import FlowCrypt

class CoreComposeMessageMock: CoreComposeMessageType {
    var composeEmailResult: ((SendableMsg, MsgFmt, [String]?) -> (CoreRes.ComposeEmail))!
    func composeEmail(msg: SendableMsg, fmt: MsgFmt, pubKeys: [String]?) throws -> CoreRes.ComposeEmail {
        composeEmailResult(msg, fmt, pubKeys)
    }
}
