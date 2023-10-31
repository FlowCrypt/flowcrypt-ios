//
//  PubKeyState.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 21/10/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

enum PubKeyState {
    case active, expired, revoked, empty, unUsableForEncryption, unUsableForSigning
}
