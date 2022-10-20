//
//  ComposeViewController+State.swift
//  FlowCrypt
//
//  Created by Ioan Moldovan on 4/6/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit

// MARK: - State Handling
extension ComposeViewController {
    func updateView(newState: State) {
        if case .searchEmails = newState, !shouldDisplaySearchResult {
            return
        }

        shouldDisplaySearchResult = false
        state = newState

        switch state {
        case .main:
            sectionsList = Section.recipientsSections + [.recipientsLabel, .password, .compose, .attachments]
            node.reloadData()
        case .searchEmails:
            let previousSectionsCount = sectionsList.count
            sectionsList = Section.recipientsSections + [.searchResults, .contacts]

            let deletedSectionsCount = previousSectionsCount - sectionsList.count

            let sectionsToReload: [Section]
            if let type = selectedRecipientType {
                sectionsToReload = sectionsList.filter { $0 != .recipients(type) }
            } else {
                sectionsToReload = sectionsList
            }

            node.performBatchUpdates {
                if deletedSectionsCount > 0 {
                    let sectionsToDelete = sectionsList.count ..< sectionsList.count + deletedSectionsCount
                    node.deleteSections(IndexSet(sectionsToDelete), with: .none)
                }

                reload(sections: sectionsToReload)
            }
        }
    }
}
