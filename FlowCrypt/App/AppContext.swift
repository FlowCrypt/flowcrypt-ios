//
//  AppContext.swift
//  FlowCrypt
//
//  Created by Tom on 30.11.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import UIKit

class AppContext {

    let globalRouter: GlobalRouterType
    let encryptedStorage: EncryptedStorageType
    let session: SessionType?
    // todo - session service should have maybe `.currentSession` on it, then we don't have to have `session` above?
    let userAccountService: SessionServiceType
    let dataService: DataServiceType
    let keyStorage: KeyStorageType
    let keyService: KeyServiceType
    let passPhraseService: PassPhraseServiceType
    let clientConfigurationService: ClientConfigurationServiceType

    private init(
        encryptedStorage: EncryptedStorageType,
        session: SessionType?,
        userAccountService: SessionServiceType,
        dataService: DataServiceType,
        keyStorage: KeyStorageType,
        keyService: KeyServiceType,
        passPhraseService: PassPhraseServiceType,
        clientConfigurationService: ClientConfigurationServiceType,
        globalRouter: GlobalRouterType
    ) {
        self.encryptedStorage = encryptedStorage
        self.session = session
        self.userAccountService = userAccountService
        self.dataService = dataService
        self.keyStorage = keyStorage // todo - keyStorage and keyService should be the same
        self.keyService = keyService
        self.passPhraseService = passPhraseService
        self.clientConfigurationService = clientConfigurationService
        self.globalRouter = globalRouter
    }

    @MainActor
    static func setUpAppContext(globalRouter: GlobalRouterType) throws -> AppContext {
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
            userAccountService: SessionService(
                encryptedStorage: encryptedStorage,
                dataService: dataService,
                googleService: GoogleUserService(
                    currentUserEmail: dataService.currentUser?.email,
                    appDelegateGoogleSessionContainer: UIApplication.shared.delegate as? AppDelegate
                )
            ),
            dataService: dataService,
            keyStorage: keyStorage,
            keyService: keyService,
            passPhraseService: passPhraseService,
            clientConfigurationService: clientConfigurationService,
            globalRouter: globalRouter
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
            clientConfigurationService: self.clientConfigurationService,
            globalRouter: globalRouter
        )
    }

    func getRequiredMailProvider() -> MailProvider {
        guard let mailProvider = getOptionalMailProvider() else {
            // todo - should throw instead
            fatalError("wrongly using mail provider when not logged in")
        }
        return mailProvider
    }

    func getOptionalMailProvider() -> MailProvider? {
        guard let currentUser = self.dataService.currentUser, let currentAuthType = self.dataService.currentAuthType else {
            return nil
        }
        return MailProvider(
            currentAuthType: currentAuthType,
            currentUser: currentUser
        )
    }

    func getBackupService() -> BackupService {
        let mailProvider = self.getRequiredMailProvider()
        return BackupService(
            backupProvider: mailProvider.backupProvider,
            messageSender: mailProvider.messageSender
        )
    }

    func getFoldersService() -> FoldersService {
        return FoldersService(
            encryptedStorage: self.encryptedStorage,
            remoteFoldersProvider: self.getRequiredMailProvider().remoteFoldersProvider
        )
    }

}
