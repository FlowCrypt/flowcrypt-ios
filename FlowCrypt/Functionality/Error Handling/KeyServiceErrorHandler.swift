//
//  KeyServiceErrorHandler.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 27.11.2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import UIKit

struct KeyServiceErrorHandler: ErrorHandler {
    func handle(error: Error, for viewController: UIViewController) -> Bool {
        let errorMessage: String?
        switch error {
        case KeyServiceError.retrieve:
            errorMessage = "keyServiceError_retrieve_error"
        case KeyServiceError.parse:
            errorMessage = "keyServiceError_retrieve_parse"
        case KeyServiceError.unexpected:
            errorMessage = "keyServiceError_retrieve_unexpected"
        default:
            errorMessage = nil
        }

        guard let message = errorMessage else { return false }

        viewController.showAlert(message: message.localized)

        return true
    }
}
