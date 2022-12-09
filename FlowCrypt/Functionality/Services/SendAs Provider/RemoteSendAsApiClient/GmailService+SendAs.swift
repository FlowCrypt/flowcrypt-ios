//
//  GmailService+SendAs.swift
//  FlowCrypt
//
//  Created by Ioan Moldovan on 06/13/22.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import GoogleAPIClientForREST_Gmail

extension GmailService: RemoteSendAsApiClient {
    func fetchSendAsList() async throws -> [SendAsModel] {
        let query = GTLRGmailQuery_UsersSettingsSendAsList.query(withUserId: .me)
        return try await withCheckedThrowingContinuation { continuation in
            self.gmailService.executeQuery(query) { _, data, error in
                if let error {
                    let gmailError = GmailApiError.convert(from: error as NSError)
                    return continuation.resume(throwing: gmailError)
                }
                guard let sendAsListResponse = data as? GTLRGmail_ListSendAsResponse else {
                    return continuation.resume(throwing: AppErr.cast("GTLRGmail_ListSendAsResponse"))
                }
                guard let sendAsList = sendAsListResponse.sendAs else {
                    return continuation.resume(throwing: GmailApiError.failedToParseData(data))
                }
                let list = sendAsList.compactMap(SendAsModel.init)

                return continuation.resume(returning: list)
            }
        }
    }
}

// MARK: - Convenience
private extension SendAsModel {
    init?(with sendAs: GTLRGmail_SendAs) {
        guard let sendAsEmail = sendAs.sendAsEmail else { return nil }
        self.init(
            displayName: sendAs.displayName ?? "",
            sendAsEmail: sendAsEmail,
            isDefault: sendAs.isDefault?.boolValue ?? false,
            verificationStatus: SendAsVerificationStatus(
                rawValue: sendAs.verificationStatus ?? "verificationStatusUnspecified"
            ) ?? .verificationStatusUnspecified
        )
    }
}
