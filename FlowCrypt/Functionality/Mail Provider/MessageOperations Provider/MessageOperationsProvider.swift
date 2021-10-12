//
//  MessageOperationsProvider.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 07.12.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import Promises

protocol MessageOperationsProvider {
    func markAsRead(message: Message, folder: String) -> Promise<Void>
    func markAsUnread(message: Message, folder: String) -> Promise<Void>
    func moveMessageToTrash(message: Message, trashPath: String?, from folder: String) -> Promise<Void>
    func delete(message: Message, form folderPath: String?) -> Promise<Void>
    func archiveMessage(message: Message, folderPath: String) -> Promise<Void>
}
