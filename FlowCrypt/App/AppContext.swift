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
    let keyService: KeyServiceType
    let passPhraseService: PassPhraseServiceType
    let clientConfigurationService: ClientConfigurationServiceType

    init(
        encryptedStorage: EncryptedStorageType,
        session: SessionType?,
        userAccountService: SessionServiceType,
        dataService: DataServiceType,
        keyService: KeyServiceType,
        passPhraseService: PassPhraseServiceType,
        clientConfigurationService: ClientConfigurationServiceType,
        globalRouter: GlobalRouterType
    ) {
        self.encryptedStorage = encryptedStorage
        self.session = session
        self.userAccountService = userAccountService
        self.dataService = dataService
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
        let keyService = KeyService(
            storage: encryptedStorage,
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
            keyService: keyService,
            passPhraseService: passPhraseService,
            clientConfigurationService: clientConfigurationService,
            globalRouter: globalRouter
        )
    }

    func withSession(_ session: SessionType?) -> AppContextWithUser {
        guard
            let authType = dataService.currentAuthType,
            let user = dataService.currentUser
        else {
            fatalError()
        }

        return AppContextWithUser(
            encryptedStorage: encryptedStorage,
            session: session,
            userAccountService: userAccountService,
            dataService: dataService,
            keyService: keyService,
            passPhraseService: passPhraseService,
            clientConfigurationService: clientConfigurationService,
            globalRouter: globalRouter,
            authType: authType,
            user: user
        )
    }

    @MainActor
    func getRequiredMailProvider() -> MailProvider {
        guard let mailProvider = getOptionalMailProvider() else {
            // todo - should throw instead
            fatalError("wrongly using mail provider when not logged in")
        }
        return mailProvider
    }

    @MainActor
    func getOptionalMailProvider() -> MailProvider? {
        guard
            let currentUser = dataService.currentUser,
            let currentAuthType = dataService.currentAuthType
        else { return nil }

        return MailProvider(
            currentAuthType: currentAuthType,
            currentUser: currentUser,
            delegate: UIApplication.shared.delegate as? AppDelegateGoogleSesssionContainer
        )
    }

    @MainActor
    func getBackupService() -> BackupService {
        let mailProvider = self.getRequiredMailProvider()
        return BackupService(
            backupProvider: mailProvider.backupProvider,
            messageSender: mailProvider.messageSender
        )
    }

    @MainActor
    func getFoldersService() -> FoldersService {
        return FoldersService(
            encryptedStorage: self.encryptedStorage,
            remoteFoldersProvider: self.getRequiredMailProvider().remoteFoldersProvider
        )
    }
}

class AppContextWithUser: AppContext {
    let authType: AuthType
    let user: User

    init(
        encryptedStorage: EncryptedStorageType,
        session: SessionType?,
        userAccountService: SessionServiceType,
        dataService: DataServiceType,
        keyService: KeyServiceType,
        passPhraseService: PassPhraseServiceType,
        clientConfigurationService: ClientConfigurationServiceType,
        globalRouter: GlobalRouterType,
        authType: AuthType,
        user: User
    ) {
        self.authType = authType
        self.user = user

        super.init(
            encryptedStorage: encryptedStorage,
            session: session,
            userAccountService: userAccountService,
            dataService: dataService,
            keyService: keyService,
            passPhraseService: passPhraseService,
            clientConfigurationService: clientConfigurationService,
            globalRouter: globalRouter
        )
    }
}
