//
//  Version6SchemaMigration.swift
//  FlowCrypt
//
//  Created by  Ivan Ushakov on 07.12.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptCommon
import RealmSwift

final class Version6SchemaMigration {
    private lazy var logger = Logger.nested(in: Self.self, with: .migration)

    private let migration: Migration

    init(migration: Migration) {
        self.migration = migration
    }

    func perform() {
        logger.logInfo("Start version 6 migration")
    }
}
