//
//  Gmail+Backup.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 27.12.2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Promises

extension GmailService: BackupProvider {
    func searchBackups(for email: String) -> Promise<Data> {
        return Promise { (resolve, reject) in
            let promises = GeneralConstants.EmailConstant.recoverAccountSearchSubject
                .map { searchExpression(using: MessageSearchContext(expression: $0)) }
            
            let messages = try await(all(promises))
                 .flatMap { $0 }
            
            print(messages)
            resolve(Data())
        }
    }
}
