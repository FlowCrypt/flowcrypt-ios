//
//  FolderPubKeyRealmObject.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 31/08/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import RealmSwift

final class FolderRealmObject: Object {
    @Persisted(primaryKey: true) var path: String
    @Persisted var name: String
    @Persisted var image: Data?
    @Persisted var itemType: String
    @Persisted var user: UserRealmObject?
}

extension FolderRealmObject {
    convenience init(folder: Folder, user: User) {
        self.init()
        self.path = folder.path
        self.name = folder.name
        self.image = folder.image
        self.itemType = folder.itemType
        self.user = UserRealmObject(user)
    }
}
