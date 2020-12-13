//
//  MessageOperationsProvider.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 07.12.2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Promises

protocol MessageOperationsProvider {
    func markAsRead(message: Message, folder: String) -> Promise<Void>
    func moveMessageToTrash(message: Message, trashPath: String?, from folder: String) -> Promise<Void>
    func delete(message: Message, form folderPath: String?) -> Promise<Void>
}
