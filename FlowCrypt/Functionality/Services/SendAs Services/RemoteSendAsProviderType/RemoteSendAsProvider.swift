//
//  RemoteSendAsProviderType.swift
//  FlowCrypt
//
//  Created by Ioan Moldovan on 06/13/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

protocol RemoteSendAsProviderType {
    func fetchSendAsList() async throws -> [SendAsModel]
}
