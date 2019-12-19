//
//  Imap+Search.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 19/12/2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Promises

protocol SearchResultsProvider {
    func search(
        expression: String,
        in folder: String,
        count: Int,
        from: Int?
    ) -> Promise<MessageContext>
}

extension Imap {
    func search(
        expression: String,
        in folder: String,
        count: Int,
        from: Int?
    ) -> Promise<MessageContext> {
        return Promise { [weak self] resolve, reject in
            guard let self = self else { return reject(AppErr.nilSelf) }
            self.getImapSess()
            
            
            
            return reject(AppErr.nilSelf)
        }
    }
}
