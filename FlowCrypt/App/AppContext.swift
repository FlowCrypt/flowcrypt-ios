//
//  AppContext.swift
//  FlowCrypt
//
//  Created by Tom on 30.11.2021
//  Copyright © 2017-present FlowCrypt a.s. All rights reserved.
//

import UIKit

class AppContext {

    let globalRouter: GlobalRouterType
    let encryptedStorage: EncryptedStorageType
    let sessionManager: SessionManagerType
    let keyAndPassPhraseStorage: KeyAndPassPhraseStorageType
    let combinedPassPhraseStorage: CombinedPassPhraseStorageType

    init(
        encryptedStorage: EncryptedStorageType,
        sessionManager: SessionManagerType,
        keyAndPassPhraseStorage: KeyAndPassPhraseStorageType,
        combinedPassPhraseStorage: CombinedPassPhraseStorageType,
        globalRouter: GlobalRouterType
    ) {
        self.encryptedStorage = encryptedStorage
        self.sessionManager = sessionManager
        self.keyAndPassPhraseStorage = keyAndPassPhraseStorage
        self.combinedPassPhraseStorage = combinedPassPhraseStorage
        self.globalRouter = globalRouter
    }

    @MainActor
    static func setup(globalRouter: GlobalRouterType) async throws -> AppContext {
        let encryptedStorage = try await EncryptedStorage()
        let combinedPassPhraseStorage = CombinedPassPhraseStorage(encryptedStorage: encryptedStorage)
        let keyAndPassPhraseStorage = KeyAndPassPhraseStorage(
            encryptedStorage: encryptedStorage,
            combinedPassPhraseStorage: combinedPassPhraseStorage
        )
        return try AppContext(
            encryptedStorage: encryptedStorage,
            sessionManager: SessionManager(
                encryptedStorage: encryptedStorage,
                googleAuthManager: GoogleAuthManager(
                    appDelegateGoogleSessionContainer: UIApplication.shared.delegate as? AppDelegate
                )
            ),
            keyAndPassPhraseStorage: keyAndPassPhraseStorage,
            combinedPassPhraseStorage: combinedPassPhraseStorage,
            globalRouter: globalRouter
        )
    }

    func with(authType: AuthType, user: User) async throws -> AppContextWithUser {
        return try await AppContextWithUser(
            encryptedStorage: encryptedStorage,
            sessionManager: sessionManager,
            keyAndPassPhraseStorage: keyAndPassPhraseStorage,
            combinedPassPhraseStorage: combinedPassPhraseStorage,
            globalRouter: globalRouter,
            authType: authType,
            user: user
        )
    }

    @MainActor
    func getRequiredMailProvider() throws -> MailProvider {
        guard let mailProvider = try getOptionalMailProvider() else {
            throw AppErr.wrongMailProvider
        }
        return mailProvider
    }

    @MainActor
    func getOptionalMailProvider() throws -> MailProvider? {
        guard
            let currentUser = try encryptedStorage.activeUser,
            let currentAuthType = currentUser.authType
        else { return nil }

        return MailProvider(
            currentAuthType: currentAuthType,
            currentUser: currentUser,
            delegate: UIApplication.shared.delegate as? AppDelegateGoogleSessionContainer
        )
    }

    @MainActor
    func getBackupsManager() throws -> BackupsManager {
        let mailProvider = try getRequiredMailProvider()
        return try BackupsManager(
            backupApiClient: mailProvider.backupApiClient,
            messageGateway: mailProvider.messageGateway
        )
    }

    @MainActor
    func getFoldersManager() throws -> FoldersManager {
        return try FoldersManager(
            encryptedStorage: encryptedStorage,
            remoteFoldersApiClient: getRequiredMailProvider().remoteFoldersApiClient
        )
    }

    @MainActor
    func getSendAsProvider() throws -> SendAsProvider {
        return try SendAsProvider(
            encryptedStorage: encryptedStorage,
            remoteSendAsApiClient: getRequiredMailProvider().remoteSendAsApiClient
        )
    }
}

class AppContextWithUser: AppContext {
    let authType: AuthType
    let user: User
    let userId: UserId

    let enterpriseServer: EnterpriseServerApiType
    let clientConfigurationProvider: ClientConfigurationProviderType

    init(
        encryptedStorage: EncryptedStorageType,
        sessionManager: SessionManagerType,
        keyAndPassPhraseStorage: KeyAndPassPhraseStorageType,
        combinedPassPhraseStorage: CombinedPassPhraseStorageType,
        globalRouter: GlobalRouterType,
        authType: AuthType,
        user: User
    ) async throws {
        self.authType = authType
        self.user = user
        self.userId = UserId(email: user.email, name: user.name)
        self.enterpriseServer = try EnterpriseServerApi(email: user.email)
        self.clientConfigurationProvider = ClientConfigurationProvider(
            server: enterpriseServer,
            local: LocalClientConfiguration(
                encryptedStorage: encryptedStorage
            )
        )

        var combinedPassPhraseStorageWithConfiguration = combinedPassPhraseStorage
        combinedPassPhraseStorageWithConfiguration.clientConfiguration = try await clientConfigurationProvider.configuration
        super.init(
            encryptedStorage: encryptedStorage,
            sessionManager: sessionManager,
            keyAndPassPhraseStorage: keyAndPassPhraseStorage,
            combinedPassPhraseStorage: combinedPassPhraseStorageWithConfiguration,
            globalRouter: globalRouter
        )
    }
}
