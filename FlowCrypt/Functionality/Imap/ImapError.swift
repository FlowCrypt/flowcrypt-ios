//
//  ImapError.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 07.12.2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation

// TODO: - ANTON - Handle Error
enum ImapError: Error {
    case missedMessageInfo(String)
}
