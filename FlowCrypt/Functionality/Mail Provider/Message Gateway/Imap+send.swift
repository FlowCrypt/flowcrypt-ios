//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import Foundation

extension Imap: MessageGateway {
    func sendMail(input: MessageGatewayInput, progressHandler: ((Float) -> Void)?) async throws {
        try await withCheckedThrowingContinuation { [weak smtpSess] (continuation: CheckedContinuation<Void, Error>) in
            guard let session = smtpSess else {
                return continuation.resume(returning: ())
            }

            session.sendOperation(with: input.mime)
                .start { error in
                    if let error = error {
                        return continuation.resume(throwing: error)
                    }
                    return continuation.resume(returning: ())
                }
        }
    }
}
