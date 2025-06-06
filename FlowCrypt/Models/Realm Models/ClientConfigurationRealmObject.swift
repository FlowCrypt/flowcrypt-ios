//
//  ClientConfigurationRealmObject.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 18.06.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import RealmSwift

final class ClientConfigurationRealmObject: Object {
    @Persisted(primaryKey: true) var userEmail: String! // swiftlint:disable:this attributes
    @Persisted var flags: Data?
    @Persisted var customKeyserverUrl: String?
    @Persisted var keyManagerUrl: String?
    @Persisted var fesUrl: String?
    @Persisted var inMemoryPassPhraseSessionLength: Int?
    @Persisted var allowAttesterSearchOnlyForDomains: Data?
    @Persisted var disallowAttesterSearchForDomains: Data?
    @Persisted var enforceKeygenAlgo: String?
    @Persisted var enforceKeygenExpireMonths: Int
    @Persisted var disallowPasswordMessagesForTerms: Data?
    @Persisted var disallowPasswordMessagesErrorText: String?

    convenience init(
        flags: [String]?,
        customKeyserverUrl: String?,
        keyManagerUrl: String?,
        fesUrl: String?,
        inMemoryPassPhraseSessionLength: Int?,
        allowAttesterSearchOnlyForDomains: [String]?,
        disallowAttesterSearchForDomains: [String]?,
        enforceKeygenAlgo: String?,
        enforceKeygenExpireMonths: Int?,
        disallowPasswordMessagesForTerms: [String]?,
        disallowPasswordMessagesErrorText: String?,
        email: String
    ) {
        self.init()
        if let flags {
            self.flags = try? JSONEncoder().encode(flags)
        }
        self.customKeyserverUrl = customKeyserverUrl
        self.keyManagerUrl = keyManagerUrl
        self.fesUrl = fesUrl
        self.inMemoryPassPhraseSessionLength = inMemoryPassPhraseSessionLength
        self.allowAttesterSearchOnlyForDomains = try? allowAttesterSearchOnlyForDomains.ifNotNil { try JSONEncoder().encode($0) }
        self.disallowAttesterSearchForDomains = try? disallowAttesterSearchForDomains.ifNotNil { try JSONEncoder().encode($0) }
        self.enforceKeygenAlgo = enforceKeygenAlgo
        self.enforceKeygenExpireMonths = enforceKeygenExpireMonths ?? -1
        self.disallowPasswordMessagesForTerms = try? disallowPasswordMessagesForTerms.ifNotNil { try JSONEncoder().encode($0) }
        self.disallowPasswordMessagesErrorText = disallowPasswordMessagesErrorText
        self.userEmail = email
    }
}

extension ClientConfigurationRealmObject {
    convenience init(configuration: RawClientConfiguration, email: String, fesUrl: String?) {
        self.init(
            flags: configuration.flags?.map(\.rawValue),
            customKeyserverUrl: configuration.customKeyserverUrl,
            keyManagerUrl: configuration.keyManagerUrl,
            fesUrl: fesUrl,
            inMemoryPassPhraseSessionLength: configuration.inMemoryPassPhraseSessionLength,
            allowAttesterSearchOnlyForDomains: configuration.allowAttesterSearchOnlyForDomains,
            disallowAttesterSearchForDomains: configuration.disallowAttesterSearchForDomains,
            enforceKeygenAlgo: configuration.enforceKeygenAlgo,
            enforceKeygenExpireMonths: configuration.enforceKeygenExpireMonths,
            disallowPasswordMessagesForTerms: configuration.disallowPasswordMessagesForTerms,
            disallowPasswordMessagesErrorText: configuration.disallowPasswordMessagesErrorText,
            email: email
        )
    }
}
