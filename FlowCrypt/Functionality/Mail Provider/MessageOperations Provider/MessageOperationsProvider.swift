//
//  MessageOperationsProvider.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 07.12.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import FlowCryptCommon

protocol MessageOperationsProvider {
    func moveMessageToTrash(message: Message, trashPath: String?, from folder: String) async throws
    func delete(message: Message, from folderPath: String?) async throws
    func moveMessageToInbox(message: Message, folderPath: String) async throws
    func archiveMessage(message: Message, folderPath: String) async throws
    func markAsUnread(message: Message, folder: String) async throws
    func markAsRead(message: Message, folder: String) async throws
    func emptyFolder(path: String) async throws
    func batchDeleteMessages(identifiers: [String], from folderPath: String?) async throws
}
