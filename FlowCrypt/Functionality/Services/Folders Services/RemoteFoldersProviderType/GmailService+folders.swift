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
                    reject(AppErr .providerError(error))
                    return
                }

                guard let listLabels = data as? GTLRGmail_ListLabelsResponse else {
                    return reject(AppErr.cast("GTLRGmail_ListLabelsResponse"))
                }

                guard let labels = listLabels.labels else {
                    return reject(GmailServiceError.failedToParseData(data))
                }

                // TODO: - Implement categories if needed
                let folders = labels
                    .compactMap { (label) -> GTLRGmail_Label? in
                        guard let identifier = label.identifier else {
                            return nil
                        }
                        guard identifier.range(of: "CATEGORY_", options: .caseInsensitive) == nil else {
                            return nil
                        }
                        return label
                    }
                    .compactMap(FolderObject.init)

                resolve(folders)
            }
        }
    }

    func saveTrashFolderPath(with folders: [MCOIMAPFolder]) {

    }
}

// MARK: - Convenience
private extension FolderObject {
    convenience init?(with folder: GTLRGmail_Label) {
        guard let name = folder.name else { return nil }
        guard let identifier = folder.identifier else {
            assertionFailure("Gmail folder \(folder) doesn't have identifier")
            return nil
        }
        self.init(
            name: name,
            path: identifier,
            image: nil
        )
    }
}
