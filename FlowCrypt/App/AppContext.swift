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
    let keyAndPassPhraseStorage: KeyAndPassPhraseStorageType
    let combinedPassPhraseStorage: CombinedPassPhraseStorageType

    init(
        encryptedStorage: EncryptedStorageType,
        session: SessionType?,
        userAccountService: SessionServiceType,
        keyAndPassPhraseStorage: KeyAndPassPhraseStorageType,
        combinedPassPhraseStorage: CombinedPassPhraseStorageType,
        globalRouter: GlobalRouterType
    ) {
        self.encryptedStorage = encryptedStorage
        self.session = session
        self.userAccountService = userAccountService
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
        var sessionType: SessionType?
        if let user = try encryptedStorage.activeUser, let authType = user.authType {
            switch authType {
            case .oAuthGmail(let token):
                sessionType = .google(user.email, name: user.name, token: token)
            case .password:
                sessionType = .session(user)
            }
        }
        return AppContext(
            encryptedStorage: encryptedStorage,
            session: sessionType,
            userAccountService: try SessionService(
                encryptedStorage: encryptedStorage,
                googleService: GoogleUserService(
                    currentUserEmail: try encryptedStorage.activeUser?.email,
                    appDelegateGoogleSessionContainer: UIApplication.shared.delegate as? AppDelegate
                )
            ),
            keyAndPassPhraseStorage: keyAndPassPhraseStorage,
            combinedPassPhraseStorage: combinedPassPhraseStorage,
            globalRouter: globalRouter
        )
    }

    func with(session: SessionType?, authType: AuthType, user: User) async throws -> AppContextWithUser {
        return try await AppContextWithUser(
            encryptedStorage: encryptedStorage,
            session: session,
            userAccountService: userAccountService,
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
    func getBackupService() throws -> BackupService {
        let mailProvider = try self.getRequiredMailProvider()
        return BackupService(
            backupProvider: try mailProvider.backupProvider,
            messageSender: try mailProvider.messageSender
        )
    }

    @MainActor
    func getFoldersService() throws -> FoldersService {
        return FoldersService(
            encryptedStorage: self.encryptedStorage,
            remoteFoldersProvider: try self.getRequiredMailProvider().remoteFoldersProvider
        )
    }

    @MainActor
    func getSendAsService() throws -> SendAsService {
        return SendAsService(
            encryptedStorage: self.encryptedStorage,
            remoteSendAsProvider: try self.getRequiredMailProvider().remoteSendAsProvider
        )
    }
}

class AppContextWithUser: AppContext {
    let authType: AuthType
    let user: User
    let userId: UserId

    let enterpriseServer: EnterpriseServerApiType
    let clientConfigurationService: ClientConfigurationServiceType

    init(
        encryptedStorage: EncryptedStorageType,
        session: SessionType?,
        userAccountService: SessionServiceType,
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
        self.clientConfigurationService = ClientConfigurationService(
            server: enterpriseServer,
            local: LocalClientConfiguration(
                encryptedStorage: encryptedStorage
            )
        )

        var combinedPassPhraseStorageWithConfiguration = combinedPassPhraseStorage
        combinedPassPhraseStorageWithConfiguration.clientConfiguration = try await clientConfigurationService.configuration
        super.init(
            encryptedStorage: encryptedStorage,
            session: session,
            userAccountService: userAccountService,
            keyAndPassPhraseStorage: keyAndPassPhraseStorage,
            combinedPassPhraseStorage: combinedPassPhraseStorageWithConfiguration,
            globalRouter: globalRouter
        )
    }
}
