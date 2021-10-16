//
//  PromiseKitExtension.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 04.06.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import MailCore
import Promises

extension Promise {
    @discardableResult
    func recoverFromTimeOut(
        on queue: DispatchQueue = .promises,
        result: Value
    ) -> Promise {
        self.recover(on: queue) { error -> Promise in
            if let promiseError = error as? PromiseError, promiseError == .timedOut {
                return Promise { resolve, _ in
                    resolve(result)
                }
            }
            return Promise { _, reject in
                reject(error)
            }
        }
    }
}
