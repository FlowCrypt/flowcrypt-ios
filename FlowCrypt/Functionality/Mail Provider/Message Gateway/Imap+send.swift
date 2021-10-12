//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import Combine
import Foundation

extension Imap: MessageGateway {
    func sendMail(input: MessageGatewayInput) async throws {
        try await withCheckedThrowingContinuation { [smtpSess] (continuation: CheckedContinuation<Void, Error>) in
            smtpSess?.sendOperation(with: input.mime)
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
