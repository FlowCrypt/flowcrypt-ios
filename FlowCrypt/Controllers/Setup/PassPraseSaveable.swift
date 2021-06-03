//
//  PassPhraseSaveable.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 02.06.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import FlowCryptUI

protocol PassPhraseSaveable {
    var shouldSaveLocally: Bool { get set }
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
        CheckBoxTextNode(input: .passPhraseLocally(isSelected: self.shouldSaveLocally))
    }

    var saveInMemoryNode: CellNode {
        CheckBoxTextNode(input: .passPhraseLocally(isSelected: !self.shouldSaveLocally))
    }

    func showPassPhraseErrorAlert() {
        showAlert(message: "setup_enter_pass_phrase".localized)
    }
}
