//
//  MessageGatewayMock.swift
//  FlowCryptAppTests
//
//  Created by Anton Kharchevskyi on 25.07.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Combine
@testable import FlowCrypt

class MessageGatewayMock: MessageGateway {
    var sendMailResult: ((Data) -> (Result<Void, Error>))!
    func sendMail(mime: Data) -> Future<Void, Error> {
        Future { promise in
            promise(self.sendMailResult(mime))
        }
    }
}
