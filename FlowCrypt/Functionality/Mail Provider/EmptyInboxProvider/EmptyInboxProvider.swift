//
//  EmptyInboxProvider.swift
//  FlowCrypt
//
//  Created by Ioan Moldovan on 6/28/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

protocol EmptyInboxProvider {
    func emptyFolder(path: String) async throws
}
