//
//  DomainRulesObject.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 18.06.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import Foundation
import RealmSwift

final class DomainRulesObject: Object {

    @objc dynamic var flags: Data?
    @objc dynamic var customKeyserverUrl: String?
    @objc dynamic var keyManagerUrl: String?
    @objc dynamic var disallowAttesterSearchForDomains: Data?
    @objc dynamic var enforceKeygenAlgo: String?
    @objc dynamic var enforceKeygenExpireMonths: Int = -1
    @objc dynamic var user: UserObject?
    @objc dynamic var userEmail: String?

    convenience init(
        flags: [String]?,
        customKeyserverUrl: String?,
        keyManagerUrl: String?,
        disallowAttesterSearchForDomains: [String]?,
        enforceKeygenAlgo: String?,
        enforceKeygenExpireMonths: Int?,
        user: UserObject?
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
        self.userEmail = user?.email
    }

    convenience init(
        _ domainRules: DomainRules,
        user: UserObject?
    ) {
        self.init(
            flags: domainRules.flags?.map(\.rawValue),
            customKeyserverUrl: domainRules.customKeyserverUrl,
            keyManagerUrl: domainRules.keyManagerUrl,
            disallowAttesterSearchForDomains: domainRules.disallowAttesterSearchForDomains,
            enforceKeygenAlgo: domainRules.enforceKeygenAlgo,
            enforceKeygenExpireMonths: domainRules.enforceKeygenExpireMonths,
            user: user
        )
    }

    override class func primaryKey() -> String? {
        "userEmail"
    }
}

extension DomainRulesObject: CachedObject {
    var identifier: String { userEmail ?? "" }

    var activeUser: UserObject? { user }
}
