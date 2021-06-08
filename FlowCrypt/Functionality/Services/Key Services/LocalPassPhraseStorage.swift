//
//  LocalPassPhraseStorage.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 07.06.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import UIKit

protocol LocalPassPhraseStorageType {
    var passPhrases: Set<LocalPassPhrase> { get }
    func save(passPhrase: LocalPassPhrase)
    func removePassPhrases(with objects: [LocalPassPhrase])
}

struct LocalPassPhrase: Codable, Hashable, Equatable {
    let passPhrase: PassPhrase
    let date: Date
}

final class LocalPassPhraseStorage: LocalPassPhraseStorageType {
    static let shared: LocalPassPhraseStorage = LocalPassPhraseStorage()

    private(set) var passPhrases: Set<LocalPassPhrase> = []

    private init() {
    }

    func save(passPhrase: LocalPassPhrase) {
        passPhrases.insert(passPhrase)
    }

    func removePassPhrases(with objects: [LocalPassPhrase]) {
        objects.forEach {
            if passPhrases.contains($0) {
                passPhrases.remove($0)
            }
        }
    }
}
