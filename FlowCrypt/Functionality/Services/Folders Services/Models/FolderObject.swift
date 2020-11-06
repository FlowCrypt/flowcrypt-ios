//
//  FolderObject.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 31/08/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation
import RealmSwift

final class FolderObject: Object {
    @objc dynamic var name: String = ""
    @objc dynamic var path: String = ""
    @objc dynamic var image: Data?
    @objc dynamic var itemType: String = FolderViewModel.ItemType.folder.rawValue

    convenience init(
        name: String,
        path: String,
        image: Data?
    ) {
        self.init()
        self.name = name
        self.path = path
        self.image = image
    }

    override class func primaryKey() -> String? {
        "path"
    }
}

extension FolderObject: CachedObject {
    var identifier: String { name }
}
