//
//  MessageGatewayMock.swift
//  FlowCryptAppTests
//
//  Created by Anton Kharchevskyi on 25.07.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

@testable import FlowCrypt
import Foundation

class MessageGatewayMock: MessageGateway {
    var sendMailResult: ((Data) -> (Result<Identifier, Error>))!
    func sendMail(input: MessageGatewayInput, progressHandler: ((Float) -> Void)?) async throws -> Identifier {
        if case .failure(let error) = sendMailResult(input.mime) {
            throw error
        }
        return .random
    }
}
