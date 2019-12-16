//
//  ViewControllerErrorHandler.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12/16/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation

enum ViewControllerError {
    enum MyMenu: Error {
        case fetchFolders, general
    }
    case menuError(MyMenu)


}

struct ViewControllerErrorHandler: ErrorHandlerType {
    func handle(error level: ErrorLevel) -> Bool {
        guard case let .viewController(viewControllerError, viewController) = level else { return false }

        switch viewControllerError {
        case ViewControllerError.menuError(.fetchFolders):
            viewController.hideSpinner()
        case ViewControllerError.menuError(.general):
            viewController.showAlert(error: viewControllerError, message: "error_fetch_folders".localized)
        default:
            return false
        }


        return true
    }


}
