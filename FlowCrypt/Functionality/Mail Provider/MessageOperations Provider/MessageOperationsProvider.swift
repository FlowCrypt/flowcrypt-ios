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
    func moveMessageToTrash(id: Identifier, trashPath: String?, from folder: String) async throws
    func deleteMessage(id: Identifier, from folderPath: String?) async throws
    func moveMessageToInbox(id: Identifier, folderPath: String) async throws
    func archiveMessage(id: Identifier, folderPath: String) async throws
    func markAsUnread(id: Identifier, folder: String) async throws
    func markAsRead(id: Identifier, folder: String) async throws
    func emptyFolder(path: String) async throws
    func batchDeleteMessages(identifiers: [String], from folderPath: String?) async throws
}
