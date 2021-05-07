//
//  GmailService+folder.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 06.11.2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation
import Promises
import GTMSessionFetcher
import GoogleAPIClientForREST

extension GmailService: RemoteFoldersProviderType {
    func fetchFolders() -> Promise<[FolderObject]> {
        Promise { (resolve, reject) in
            let query = GTLRGmailQuery_UsersLabelsList.query(withUserId: .me)

            self.gmailService.executeQuery(query) { (_, data, error) in
                if let error = error {
                    reject(GmailServiceError.providerError(error))
                    return
                }

                guard let listLabels = data as? GTLRGmail_ListLabelsResponse else {
                    return reject(AppErr.cast("GTLRGmail_ListLabelsResponse"))
                }

                guard let labels = listLabels.labels else {
                    return reject(GmailServiceError.failedToParseData(data))
                }

                // TODO: - TOM - Implement categories if needed
                let folders = labels
                    .compactMap { (label) -> GTLRGmail_Label? in
                        guard let identifier = label.identifier, identifier.isNotEmpty else {
                            logger.logInfo("skip label with \(label.identifier ?? "")")
                            return nil
                        }
                        guard identifier.range(of: "CATEGORY_", options: .caseInsensitive) == nil else {
                            logger.logInfo("Skip category label with \(label.identifier ?? "")")
                            return nil
                        }
                        return label
                    }
                    .compactMap {
                        FolderObject(with: $0, user: self.activeUser)
                    }

                resolve(folders + [self.allMailFolder])
            }
        }
    }

    private var activeUser: UserObject? {
        EncryptedStorage().activeUser
    }

    private var allMailFolder: FolderObject {
        FolderObject(name: "All Mail", path: "all mail", image: nil, user: activeUser)
    }
}

// MARK: - Convenience
private extension FolderObject {
    convenience init?(with folder: GTLRGmail_Label, user: UserObject?) {
        guard let name = folder.name else { return nil }
        guard let identifier = folder.identifier else {
            assertionFailure("Gmail folder \(folder) doesn't have identifier")
            return nil
        }
        // folder.identifier is missed for hidden GTLRGmail_Labels
        if identifier.isEmpty {
            return nil
        }

        self.init(
            name: name,
            path: identifier,
            image: nil,
            user: user
        )
    }
}
