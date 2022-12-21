//
//  MessageAction.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 21.10.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit

typealias MessageActionCompletion = (MessageAction, InboxItem) -> Void

enum MessageAction: String, Equatable {
    case moveToTrash, moveToInbox, archive, markAsRead, markAsUnread, permanentlyDelete

    var imageName: String {
        switch self {
        case .moveToTrash, .permanentlyDelete:
            return "trash"
        case .moveToInbox:
            return "tray.and.arrow.up"
        case .archive:
            return "tray.and.arrow.down"
        case .markAsUnread:
            return "envelope"
        case .markAsRead:
            return "envelope.open"
        }
    }

    var image: UIImage? { UIImage(systemName: imageName) }

    var color: UIColor {
        switch self {
        case .moveToTrash, .permanentlyDelete:
            return .red
        case .moveToInbox, .archive, .markAsRead, .markAsUnread:
            return .main
        }
    }

    var actionStyle: UIContextualAction.Style {
        switch self {
        case .moveToTrash, .permanentlyDelete:
            return .destructive
        case .moveToInbox, .archive, .markAsRead, .markAsUnread:
            return .normal
        }
    }

    var accessibilityIdentifier: String {
        switch self {
        case .moveToTrash, .permanentlyDelete:
            return "aid-delete-button"
        case .moveToInbox:
            return "aid-move-to-inbox-button"
        case .archive:
            return "aid-archive-button"
        case .markAsRead:
            return "aid-read-button"
        case .markAsUnread:
            return "aid-unread-button"
        }
    }

    var successMessage: String? {
        switch self {
        case .moveToTrash: return "email_removed".localized
        case .moveToInbox: return "email_moved_to_inbox".localized
        case .archive: return "email_archived".localized
        case .permanentlyDelete: return "email_deleted".localized
        case .markAsRead, .markAsUnread: return nil
        }
    }

    var error: String? {
        switch self {
        case .moveToTrash: return "error_move_trash".localized
        case .moveToInbox: return "error_move_inbox".localized
        case .archive: return "error_archive".localized
        case .permanentlyDelete: return "error_permanently_delete".localized
        case .markAsRead, .markAsUnread: return nil
        }
    }
}
