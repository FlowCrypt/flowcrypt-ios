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
    @objc dynamic var name: String = ""
    @objc dynamic var path: String = ""
    @objc dynamic var image: Data?
    @objc dynamic var itemType: String = FolderViewModel.ItemType.folder.rawValue
    @objc dynamic var user: UserRealmObject!

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

    override class func primaryKey() -> String? {
        "path"
    }
}

extension FolderRealmObject: CachedRealmObject {
    var identifier: String { name }

    var activeUser: UserRealmObject? { user }
}
