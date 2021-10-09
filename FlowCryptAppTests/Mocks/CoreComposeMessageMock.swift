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
    
    var composeEmailResult: ((SendableMsg, MsgFmt) -> (CoreRes.ComposeEmail))!
    func composeEmail(msg: SendableMsg, fmt: MsgFmt) -> Future<CoreRes.ComposeEmail, Error> {
        Future<CoreRes.ComposeEmail, Error> { [weak self] promise in
            guard let self = self else { return }
            promise(.success(self.composeEmailResult(msg, fmt)))
        }
    }
}
