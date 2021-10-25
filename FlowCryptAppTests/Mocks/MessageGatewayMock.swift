//
//  MessageGatewayMock.swift
//  FlowCryptAppTests
//
//  Created by Anton Kharchevskyi on 25.07.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Combine
@testable import FlowCrypt
import Foundation

class MessageGatewayMock: MessageGateway {
    var sendMailResult: ((Data) -> (Result<Void, Error>))!
    func sendMail(input: MessageGatewayInput) async throws {
        if case .failure(let error) = sendMailResult(input.mime) {
            throw error
        }
    }
}
