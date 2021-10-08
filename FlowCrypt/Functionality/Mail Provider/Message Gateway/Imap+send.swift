//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import Combine
import Foundation

extension Imap: MessageGateway {
    func sendMail(input: MessageGatewayInput) -> Future<Void, Error> {
        Future { [smtpSess] promise in
            smtpSess?.sendOperation(with: input.mime)
                .start { error in
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        promise(.success(()))
                    }
                }
        }
    }
}
