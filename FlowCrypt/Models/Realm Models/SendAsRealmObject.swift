//
//  SendAsRealmObject.swift
//  FlowCrypt
//
//  Created by Ioan Moldovan on 6/13/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import RealmSwift

final class SendAsRealmObject: Object {
    @Persisted(primaryKey: true) var sendAsEmail: String
    @Persisted var displayName: String
    @Persisted var verificationStatus: String
    @Persisted var isDefault: Bool
    @Persisted var user: UserRealmObject?
}

extension SendAsRealmObject {
    convenience init(sendAs: SendAsModel, user: User) {
        self.init()
        self.displayName = sendAs.displayName
        self.sendAsEmail = sendAs.sendAsEmail
        self.verificationStatus = sendAs.verificationStatus.rawValue
        self.isDefault = sendAs.isDefault
        self.user = UserRealmObject(user)
    }
}
