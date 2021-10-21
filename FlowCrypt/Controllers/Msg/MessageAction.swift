//
//  MessageAction.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 21.10.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//
    

import Foundation

enum MessageAction {
    case moveToTrash, archive, changeReadFlag, permanentlyDelete

    var text: String? {
        switch self {
        case .moveToTrash: return "email_removed".localized
        case .archive: return "email_archived".localized
        case .permanentlyDelete: return "email_deleted".localized
        case .changeReadFlag: return nil
        }
    }

    var error: String? {
        switch self {
        case .moveToTrash: return "error_move_trash".localized
        case .archive: return "error_archive".localized
        case .permanentlyDelete: return "error_permanently_delete".localized
        case .changeReadFlag: return nil
        }
    }
}
