//
//  SendAsService.swift
//  FlowCrypt
//
//  Created by Ioan Moldovan on 06/13/22.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon

protocol SendAsServiceType {
    func fetchList(isForceReload: Bool, for user: User) async throws -> [SendAsModel]
}

final class SendAsService: SendAsServiceType {
    private let localSendAsProvider: LocalSendAsProviderType
    private let remoteSendAsProvider: RemoteSendAsProviderType

    init(
        encryptedStorage: EncryptedStorageType,
        localSendAsProvider: LocalSendAsProviderType? = nil,
        remoteSendAsProvider: RemoteSendAsProviderType
    ) {
        self.localSendAsProvider = localSendAsProvider ?? LocalSendAsProvider(encryptedStorage: encryptedStorage)
        self.remoteSendAsProvider = remoteSendAsProvider
    }

    func fetchList(isForceReload: Bool, for user: User) async throws -> [SendAsModel] {
        if isForceReload {
            return try await getAndSaveList(for: user)
        }
        let localList = try localSendAsProvider.fetchList(for: user.email)
        if localList.isEmpty {
            return try await getAndSaveList(for: user)
        }
        return localList
    }

    @discardableResult
    private func getAndSaveList(for user: User) async throws -> [SendAsModel] {
        let fetchedList = try await self.remoteSendAsProvider.fetchSendAsList()
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                do {
                    try self.localSendAsProvider.removeList(for: user.email)

                    // save to Realm
                    try self.localSendAsProvider.save(list: fetchedList, for: user)

                    // return list
                    return continuation.resume(returning: fetchedList)
                } catch {
                    return continuation.resume(throwing: error)
                }
            }
        }
    }
}
