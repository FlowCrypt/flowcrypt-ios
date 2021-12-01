//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import MailCore

extension Imap {
    
    func fetchMsg(message: MCOIMAPMessage, folder: String) async throws -> Data {
        return try await execute("fetchMsg", { sess, respond in
            sess.fetchMessageOperation(
                withFolder: folder,
                uid: message.uid
            ).start { error, value in respond(error, value) }
        })
    }
}
