//
//  MessageProvider.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 29.11.2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Promises

protocol MessageProvider {
    func fetchMsg(message: Message, folder: String) -> Promise<Data>
}
