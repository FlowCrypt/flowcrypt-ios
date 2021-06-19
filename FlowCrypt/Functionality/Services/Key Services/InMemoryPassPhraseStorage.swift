//
//  LocalPassPhraseStorage.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 07.06.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import UIKit

protocol InMemoryPassPhraseStorageType {
    var passPhrases: Set<InMemoryPassPhrase> { get }
    func save(passPhrase: InMemoryPassPhrase)
    func removePassPhrases(with objects: [InMemoryPassPhrase])
}

struct InMemoryPassPhrase: Codable, Hashable, Equatable {
    let passPhrase: PassPhrase
    let date: Date

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.passPhrase.longid == rhs.passPhrase.longid
    }
}

final class InMemoryPassPhraseStorage: InMemoryPassPhraseStorageType {
    static let shared: InMemoryPassPhraseStorage = InMemoryPassPhraseStorage()

    private(set) var passPhrases: Set<InMemoryPassPhrase> = []

    private init() {
    }

    func save(passPhrase: InMemoryPassPhrase) {
        passPhrases.insert(passPhrase)
    }

    func removePassPhrases(with objects: [InMemoryPassPhrase]) {
        objects.forEach {
            if passPhrases.contains($0) {
                passPhrases.remove($0)
            }
        }
    }
}
