//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Promises

extension Imap: MessageSender {
    func sendMail(mime: Data) -> Promise<Void> {
        Promise { [weak self] resolve, reject in
            guard let self = self else { return reject(AppErr.nilSelf) }
            self.smtpSess?
                .sendOperation(with: mime)
                .start(self.finalizeVoid("send", resolve, reject, retry: { self.sendMail(mime: mime) }))
        }
    }
}
