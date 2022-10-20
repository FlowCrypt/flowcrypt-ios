//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import Foundation

extension Imap: MessageGateway {
    func sendMail(input: MessageGatewayInput, progressHandler: ((Float) -> Void)?) async throws -> Identifier {
        try await withCheckedThrowingContinuation { [weak self] continuation in
            do {
                let session = try self?.smtpSess
                session?.sendOperation(with: input.mime)
                    .start { error in
                        if let error {
                            return continuation.resume(throwing: error)
                        }
                        return continuation.resume(throwing: AppErr.unexpected("Not implemented"))
                    }
            } catch {
                return continuation.resume(throwing: ImapError.noSession)
            }
        }
    }
}
