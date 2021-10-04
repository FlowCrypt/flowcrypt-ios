//
//  PassPhraseSaveable.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 02.06.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import FlowCryptUI

protocol PassPhraseSaveable {
    var shouldStorePassPhrase: Bool { get set }
    var passPhraseIndexes: [IndexPath] { get }
    var saveLocallyNode: CellNode { get }
    var saveInMemoryNode: CellNode { get }

    var passPhraseService: PassPhraseServiceType { get }

    func handleSelectedPassPhraseOption()
    func showPassPhraseErrorAlert()
}

extension PassPhraseSaveable where Self: TableNodeViewController {
    func handleSelectedPassPhraseOption() {
        node.reloadRows(at: passPhraseIndexes, with: .automatic)
    }

    var saveLocallyNode: CellNode {
        CheckBoxTextNode(input: .passPhraseLocally(isSelected: self.shouldStorePassPhrase))
    }

    var saveInMemoryNode: CellNode {
        CheckBoxTextNode(input: .passPhraseMemory(isSelected: !self.shouldStorePassPhrase))
    }

    func showPassPhraseErrorAlert() {
        showAlert(message: "setup_enter_pass_phrase".localized)
    }
}
