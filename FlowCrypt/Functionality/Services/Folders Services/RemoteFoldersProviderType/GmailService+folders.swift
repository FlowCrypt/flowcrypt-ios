//
//  GmailService+folder.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 06.11.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import GoogleAPIClientForREST
import GTMSessionFetcher
import Promises

extension GmailService: RemoteFoldersProviderType {
    enum Constants {
        static let allMailFolder = Folder(name: "All Mail", path: "", image: nil)
    }

    func fetchFolders() -> Promise<[Folder]> {
        Promise { resolve, reject in
            let query = GTLRGmailQuery_UsersLabelsList.query(withUserId: .me)

            self.gmailService.executeQuery(query) { _, data, error in
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
                    .compactMap { label -> GTLRGmail_Label? in
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
                    .compactMap(Folder.init)

                resolve(folders + [Constants.allMailFolder])
            }
        }
    }
}

// MARK: - Convenience
private extension Folder {
    init?(with gmailFolder: GTLRGmail_Label) {
        guard let name = gmailFolder.name else { return nil }
        guard let path = gmailFolder.identifier else {
            assertionFailure("Gmail folder \(gmailFolder) doesn't have identifier")
            return nil
        }
        // folder.identifier is missed for hidden GTLRGmail_Labels
        if path.isEmpty {
            return nil
        }

        self.init(
            name: name,
            path: path,
            image: nil
        )
    }
}
