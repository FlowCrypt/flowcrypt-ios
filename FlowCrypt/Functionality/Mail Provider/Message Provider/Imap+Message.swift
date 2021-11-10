//
//  Imap+Message.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 29.11.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import Promises

extension Imap: MessageProvider {
    func fetchMsg(message: Message,
                  folder: String,
                  progressHandler: ((MessageFetchState) -> Void)?) async throws -> Data {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data, Error>) in
            guard let identifier = message.identifier.intId else {
                assertionFailure()
                return continuation.resume(throwing: AppErr.unexpected("Missed message identifier"))
            }
            let retry = { Promise<Data> { resolve, reject in
                Task {
                    do {
                        let data = try await self.fetchMsg(message: message, folder: folder, progressHandler: progressHandler)
                        resolve(data)
                    } catch {
                        reject(error)
                    }
                }
            }}

            self.imapSess?
                .fetchMessageOperation(withFolder: folder, uid: UInt32(identifier))
                .start(self.finalize(
                    "fetchMsg",
                    { return continuation.resume(returning: $0) },
                    { return continuation.resume(throwing: $0) },
                    retry: retry
                ))
        }
    }
}
