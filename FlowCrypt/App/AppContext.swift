//
//  AppContext.swift
//  FlowCrypt
//
//  Created by Tom on 30.11.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

class AppContext {

    let encryptedStorage: EncryptedStorageType
    let session: SessionType?
    // todo - should be called sessionService
    // also should have maybe `.currentSession` on it, then we don't have to have `session` above?
    let userAccountService: UserAccountServiceType
    let dataService: DataServiceType
    let keyStorage: KeyStorageType
    let keyService: KeyServiceType
    let passPhraseService: PassPhraseServiceType
    let clientConfigurationService: ClientConfigurationServiceType

    private init(
        encryptedStorage: EncryptedStorageType,
        session: SessionType?,
        userAccountService: UserAccountServiceType,
        dataService: DataServiceType,
        keyStorage: KeyStorageType,
        keyService: KeyServiceType,
        passPhraseService: PassPhraseServiceType,
        clientConfigurationService: ClientConfigurationServiceType
    ) {
        self.encryptedStorage = encryptedStorage
        self.session = session
        self.userAccountService = userAccountService
        self.dataService = dataService
        self.keyStorage = keyStorage // todo - keyStorage and keyService should be the same
        self.keyService = keyService
        self.passPhraseService = passPhraseService
        self.clientConfigurationService = clientConfigurationService
    }

    @MainActor
    static func setUpAppContext() throws -> AppContext {
        let keyChainService = KeyChainService()
        let encryptedStorage = EncryptedStorage(
            storageEncryptionKey: try keyChainService.getStorageEncryptionKey()
        )
        let dataService = DataService(encryptedStorage: encryptedStorage)
        let passPhraseService = PassPhraseService(encryptedStorage: encryptedStorage)
        let keyStorage = KeyDataStorage(encryptedStorage: encryptedStorage)
        let keyService = KeyService(
            storage: keyStorage,
            passPhraseService: passPhraseService,
            currentUserEmail: { dataService.email }
        )
        let clientConfigurationService = ClientConfigurationService(
            local: LocalClientConfiguration(
                encryptedStorage: encryptedStorage
            )
        )
        return AppContext(
            encryptedStorage: encryptedStorage,
            session: nil, // will be set later. But would be nice to already set here, if available
            userAccountService: UserAccountService(
                encryptedStorage: encryptedStorage,
                dataService: dataService
            ),
            dataService: dataService,
            keyStorage: keyStorage,
            keyService: keyService,
            passPhraseService: passPhraseService,
            clientConfigurationService: clientConfigurationService
        )
    }

    func withSession(_ session: SessionType?) -> AppContext {
        return AppContext(
            encryptedStorage: self.encryptedStorage,
            session: session,
            userAccountService: self.userAccountService,
            dataService: self.dataService,
            keyStorage: self.keyStorage,
            keyService: self.keyService,
            passPhraseService: self.passPhraseService,
            clientConfigurationService: self.clientConfigurationService
        )
    }

}
