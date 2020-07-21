//
//  ErrorHandler.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 20/07/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import UIKit

extension UIViewController {
    func handleCommon(error: Error) {
        switch error {
        case KeyServiceError.retrieve:
            showAlert(message: "Could not retrieve keys from DataService. Please restart the app and try again.")
        case KeyServiceError.parse:
            showAlert(message: "Could not parse keys from storage. Please reinstall the app.")
        case KeyServiceError.unexpected:
            showAlert(message: "Could not import key. Please try to relogin.")
        default:
            assertionFailure("Error \(error) is not handled yet")
        }
    }
}
