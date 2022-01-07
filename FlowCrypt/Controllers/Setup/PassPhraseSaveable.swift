//
//  PassPhraseSaveable.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 02.06.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptUI

@MainActor
protocol PassPhraseSaveable {
    var storageMethod: StorageMethod { get set }
    var passPhraseIndexes: [IndexPath] { get }
    var saveLocallyNode: CellNode { get }
    var saveInMemoryNode: CellNode { get }
    func handleSelectedPassPhraseOption()
    func showPassPhraseErrorAlert()
}

extension PassPhraseSaveable where Self: TableNodeViewController {
    func handleSelectedPassPhraseOption() {
        node.reloadRows(at: passPhraseIndexes, with: .automatic)
    }

    var saveLocallyNode: CellNode {
        CheckBoxTextNode(input: .passPhraseLocally(isSelected: storageMethod == .persistent))
    }

    var saveInMemoryNode: CellNode {
        CheckBoxTextNode(input: .passPhraseMemory(isSelected: storageMethod == .memory))
    }

    func showPassPhraseErrorAlert() {
        showAlert(message: "setup_enter_pass_phrase".localized)
    }
}
