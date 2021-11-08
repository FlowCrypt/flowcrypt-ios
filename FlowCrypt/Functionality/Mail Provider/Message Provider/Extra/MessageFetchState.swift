//
//  MessageFetchState.swift
//  FlowCrypt
//
//  Created by Evgenii Kyivskyi on 11/9/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//
    

import Foundation

// MARK: - MessageFetchState
enum MessageFetchState {
    case fetch, download(Float), decrypt
}
