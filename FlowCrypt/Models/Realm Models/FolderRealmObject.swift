//
//  FolderPubKeyRealmObject.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 31/08/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import RealmSwift

final class FolderRealmObject: Object {
    @Persisted(primaryKey: true) var path: String = ""
    @Persisted var name: String = ""
    @Persisted var image: Data?
    @Persisted var itemType: String = FolderViewModel.ItemType.folder.rawValue
    @Persisted var user: UserRealmObject!

    convenience init(
        name: String,
        path: String,
        image: Data?,
        user: UserRealmObject
    ) {
        self.init()
        self.name = name
        self.path = path
        self.image = image
        self.user = user
    }
}

extension FolderRealmObject: CachedRealmObject {
    var identifier: String { name }

    var activeUser: UserRealmObject? { user }
}
