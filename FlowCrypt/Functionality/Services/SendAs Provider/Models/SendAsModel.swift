//
//  SendAsModel.swift
//  FlowCrypt
//
//  Created by Ioan Moldovan on 6/13/22.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit

struct SendAsModel {
    let displayName: String
    let sendAsEmail: String
    let isDefault: Bool
    let signature: String
    let verificationStatus: SendAsVerificationStatus

    var description: String {
        if displayName.isEmpty {
            return sendAsEmail
        }
        return "\(sendAsEmail) (\(displayName))"
    }
}

enum SendAsVerificationStatus: String {
    case verificationStatusUnspecified // Unspecified verification status.
    case accepted // The address is ready to use as a send-as alias.
    case pending // The address is awaiting verification by the owner.
}

// MARK: - Map from realm model
extension SendAsModel {
    init(_ object: SendAsRealmObject) {
        self.init(
            displayName: object.displayName,
            sendAsEmail: object.sendAsEmail,
            isDefault: object.isDefault,
            signature: object.signature,
            verificationStatus: SendAsVerificationStatus(rawValue: object.verificationStatus) ?? .verificationStatusUnspecified
        )
    }
}
