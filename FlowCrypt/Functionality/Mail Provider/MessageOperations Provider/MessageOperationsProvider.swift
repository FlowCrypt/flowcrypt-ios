//
//  MessageOperationsProvider.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 07.12.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import Promises
import FlowCryptCommon

protocol MessageOperationsProvider {
    func moveMessageToTrash(message: Message, trashPath: String?, from folder: String) async throws
    func delete(message: Message, form folderPath: String?) async throws
    func archiveMessage(message: Message, folderPath: String) async throws
    func markAsUnread(message: Message, folder: String) async throws
    func markAsRead(message: Message, folder: String) async throws
}
