//
//  GmailService+folder.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 06.11.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import GoogleAPIClientForREST_Gmail

extension GmailService: RemoteFoldersProviderType {
    enum Constants {
        static let allMailFolder = Folder(path: "", name: "All Mail", image: nil)
    }

    func fetchFolders() async throws -> [Folder] {
        let query = GTLRGmailQuery_UsersLabelsList.query(withUserId: .me)
        return try await withCheckedThrowingContinuation { continuation in
            self.gmailService.executeQuery(query) { _, data, error in
                if let error = error {
                    return continuation.resume(throwing: GmailServiceError.providerError(error))
                }
                guard let listLabels = data as? GTLRGmail_ListLabelsResponse else {
                    return continuation.resume(throwing: AppErr.cast("GTLRGmail_ListLabelsResponse"))
                }
                guard let labels = listLabels.labels else {
                    return continuation.resume(throwing: GmailServiceError.failedToParseData(data))
                }
                let folders = labels
                    .compactMap { [weak self] label -> GTLRGmail_Label? in
                        guard let identifier = label.identifier, identifier.isNotEmpty else {
                            self?.logger.logDebug("skip label with \(label.identifier ?? "")")
                            return nil
                        }
                        guard identifier.range(of: "CATEGORY_", options: .caseInsensitive) == nil else {
                            self?.logger.logDebug("Skip category label with \(label.identifier ?? "")")
                            return nil
                        }
                        return label
                    }
                    .compactMap(Folder.init)

                return continuation.resume(returning: folders + [Constants.allMailFolder])
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
        // folder.identifier is missing for hidden GTLRGmail_Labels
        if path.isEmpty {
            return nil
        }

        self.init(
            path: path,
            name: name,
            image: nil
        )
    }
}
