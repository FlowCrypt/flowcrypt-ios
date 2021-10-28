//
//  DraftsListProvider.swift
//  FlowCrypt
//
//  Created by Evgenii Kyivskyi on 10/20/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//
    

import Foundation

protocol DraftsListProvider {
    func fetchDrafts(using context: FetchMessageContext) async throws -> MessageContext
}
