//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import Foundation

extension Imap: MessageGateway {
    func sendMail(input: MessageGatewayInput, progressHandler: ((Float) -> Void)?) async throws {
        try await withCheckedThrowingContinuation { [weak smtpSess] (continuation: CheckedContinuation<Void, Error>) in
            guard let session = smtpSess else {
                continuation.resume(returning: ())
                return
            }

            session.sendOperation(with: input.mime)
                .start { error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: ())
                    }
                }
        }
    }
}
