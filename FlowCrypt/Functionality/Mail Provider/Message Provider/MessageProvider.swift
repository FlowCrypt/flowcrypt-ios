//
//  MessageProvider.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 29.11.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

protocol MessageProvider {
    func fetchMsg(id: Identifier, folder: String) async throws -> Message
    func fetchAttachment(
        id: Identifier,
        messageId: Identifier,
        estimatedSize: Float?,
        progressHandler: ((Float) -> Void)?
    ) async throws -> Data
}

extension MessageProvider {
    func fetchAttachment(id: Identifier, messageId: Identifier) async throws -> Data {
        return try await fetchAttachment(id: id, messageId: messageId, estimatedSize: nil, progressHandler: nil)
    }
}
