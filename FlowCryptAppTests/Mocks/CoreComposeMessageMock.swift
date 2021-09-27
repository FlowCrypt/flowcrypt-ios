//
//  CoreComposeMessageMock.swift
//  FlowCryptAppTests
//
//  Created by Anton Kharchevskyi on 25.07.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Combine
@testable import FlowCrypt

class CoreComposeMessageMock: CoreComposeMessageType {
    
    var composeEmailResult: ((SendableMsg, MsgFmt, [String]?) -> (CoreRes.ComposeEmail))!
    func composeEmail(msg: SendableMsg, fmt: MsgFmt, pubKeys: [String]?) -> Future<CoreRes.ComposeEmail, Error> {
        Future<CoreRes.ComposeEmail, Error> { [weak self] promise in
            guard let self = self else { return }
            promise(.success(self.composeEmailResult(msg, fmt, pubKeys)))
        }
    }
}
