//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Combine

extension Imap: MessageGateway {
    func sendMail(mime: Data) -> Future<Void, Error> {
        Future { [weak self] promise in
            guard let self = self else { return promise(.failure(AppErr.nilSelf)) }

            self.smtpSess?
                .sendOperation(with: mime)
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
