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
    let keyService: KeyServiceType
    let passPhraseService: PassPhraseServiceType

    init(
        encryptedStorage: EncryptedStorageType,
        session: SessionType?,
        userAccountService: SessionServiceType,
        keyService: KeyServiceType,
        passPhraseService: PassPhraseServiceType,
        globalRouter: GlobalRouterType
    ) {
        self.encryptedStorage = encryptedStorage
        self.session = session
        self.userAccountService = userAccountService
        self.keyService = keyService
        self.passPhraseService = passPhraseService
        self.globalRouter = globalRouter
    }

    @MainActor
    static func setup(globalRouter: GlobalRouterType) throws -> AppContext {
        let keyChainService = KeyChainService()
        let encryptedStorage = EncryptedStorage(
            storageEncryptionKey: try keyChainService.getStorageEncryptionKey()
        )
        let passPhraseService = PassPhraseService(encryptedStorage: encryptedStorage)
        let keyService = KeyService(
            storage: encryptedStorage,
            passPhraseService: passPhraseService,
            currentUserEmail: { try? encryptedStorage.activeUser?.email }
        )
        return AppContext(
            encryptedStorage: encryptedStorage,
            session: nil, // will be set later. But would be nice to already set here, if available
            userAccountService: try SessionService(
                encryptedStorage: encryptedStorage,
                googleService: GoogleUserService(
                    currentUserEmail: try encryptedStorage.activeUser?.email,
                    appDelegateGoogleSessionContainer: UIApplication.shared.delegate as? AppDelegate
                )
            ),
            keyService: keyService,
            passPhraseService: passPhraseService,
            globalRouter: globalRouter
        )
    }

    func with(session: SessionType?, authType: AuthType, user: User) -> AppContextWithUser {
        return AppContextWithUser(
            encryptedStorage: encryptedStorage,
            session: session,
            userAccountService: userAccountService,
            keyService: keyService,
            passPhraseService: passPhraseService,
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
            let currentUser = try? encryptedStorage.activeUser,
            let currentAuthType = currentUser.authType
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

    let enterpriseServer: EnterpriseServerApiType
    let clientConfigurationService: ClientConfigurationServiceType

    var userId: UserId {
        UserId(email: user.email, name: user.name)
    }

    init(
        encryptedStorage: EncryptedStorageType,
        session: SessionType?,
        userAccountService: SessionServiceType,
        keyService: KeyServiceType,
        passPhraseService: PassPhraseServiceType,
        globalRouter: GlobalRouterType,
        authType: AuthType,
        user: User
    ) {
        self.authType = authType
        self.user = user
        self.enterpriseServer = EnterpriseServerApi(email: user.email)
        self.clientConfigurationService = ClientConfigurationService(
            server: enterpriseServer,
            local: LocalClientConfiguration(
                encryptedStorage: encryptedStorage
            )
        )

        super.init(
            encryptedStorage: encryptedStorage,
            session: session,
            userAccountService: userAccountService,
            keyService: keyService,
            passPhraseService: passPhraseService,
            globalRouter: globalRouter
        )
    }
}
