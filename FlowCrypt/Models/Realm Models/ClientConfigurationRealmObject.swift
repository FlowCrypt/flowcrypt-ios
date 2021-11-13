//
//  ClientConfigurationRealmObject.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 18.06.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import RealmSwift

final class ClientConfigurationRealmObject: Object {
    @Persisted(primaryKey: true) var userEmail: String!
    @Persisted var flags: Data?
    @Persisted var customKeyserverUrl: String?
    @Persisted var keyManagerUrl: String?
    @Persisted var disallowAttesterSearchForDomains: Data?
    @Persisted var enforceKeygenAlgo: String?
    @Persisted var enforceKeygenExpireMonths: Int = -1
    @Persisted var user: UserRealmObject!

    convenience init(
        flags: [String]?,
        customKeyserverUrl: String?,
        keyManagerUrl: String?,
        disallowAttesterSearchForDomains: [String]?,
        enforceKeygenAlgo: String?,
        enforceKeygenExpireMonths: Int?,
        user: UserRealmObject
    ) {
        self.init()
        if let flags = flags {
            self.flags = try? JSONEncoder().encode(flags)
        }
        self.customKeyserverUrl = customKeyserverUrl
        self.keyManagerUrl = keyManagerUrl
        if let disallowAttesterSearchForDomains = disallowAttesterSearchForDomains {
            self.disallowAttesterSearchForDomains = try? JSONEncoder().encode(disallowAttesterSearchForDomains)
        }
        self.enforceKeygenAlgo = enforceKeygenAlgo
        self.enforceKeygenExpireMonths = enforceKeygenExpireMonths ?? -1
        self.user = user
        self.userEmail = user.email
    }

    convenience init(
        _ clientConfiguration: RawClientConfiguration,
        user: UserRealmObject
    ) {
        self.init(
            flags: clientConfiguration.flags?.map(\.rawValue),
            customKeyserverUrl: clientConfiguration.customKeyserverUrl,
            keyManagerUrl: clientConfiguration.keyManagerUrl,
            disallowAttesterSearchForDomains: clientConfiguration.disallowAttesterSearchForDomains,
            enforceKeygenAlgo: clientConfiguration.enforceKeygenAlgo,
            enforceKeygenExpireMonths: clientConfiguration.enforceKeygenExpireMonths,
            user: user
        )
    }
}

extension ClientConfigurationRealmObject: CachedRealmObject {
    var identifier: String { userEmail ?? "" }

    var activeUser: UserRealmObject? { user }
}
