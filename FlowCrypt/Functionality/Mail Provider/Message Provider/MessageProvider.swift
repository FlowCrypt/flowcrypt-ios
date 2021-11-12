//
//  MessageProvider.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 29.11.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

protocol MessageProvider {
    func fetchMsg(message: Message,
                  folder: String,
                  progressHandler: ((MessageFetchState) -> Void)?) async throws -> Data
}
