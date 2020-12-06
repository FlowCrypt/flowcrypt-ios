//
//  MessageLabel.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 06.12.2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation

struct MessageLabel: Equatable {
    let type: MessageLabelType
}

enum MessageLabelType: Equatable {
    case seen
    case unread
    case starred
    case sent
    case trash
    case draft
    case important
    case label(String)

    var value: String {
        switch self {
        case .label(let result): return result
        case .unread: return "UNREAD" // Gmail supports UNREAD flag
        case .seen: return "seen" // IMAP supports seen
        case .starred: return "STARRED"
        case .sent: return "SENT"
        case .trash: return "TRASH"
        case .draft: return "DRAFT"
        case .important: return "IMPORTANT"
        }
    }
}

// MARK: - IMAP Flags
extension MessageLabelType {
    // swiftlint:disable cyclomatic_complexity
    init(imapFlag: MCOMessageFlag) {
        switch imapFlag {
        case .seen: self = .seen
        case .flagged: self = .starred
        case .mdnSent: self = .sent
        case .deleted: self = .trash
        case .draft: self = .draft
        // Supported only by imap
        case .answered: self = .label("answered")
        case .forwarded: self = .label("forwarded")
        case .submitPending: self = .label("pending")
        case .submitted: self = .label("submited")
        default:
            if imapFlag.rawValue == 0 {
                self = .unread
            } else {
                self = .label(String(imapFlag.rawValue))
            }
        }
    }
}

// MARK: - GMAIL
extension MessageLabelType {
    init(gmailLabel: String) {
        let types: [MessageLabelType] = [.seen, .unread, .starred, .sent, .trash, .draft, .important]
        let all = types.map { type in
            return (type, type.value)
        }
        guard let label = all.first(where: { $0.1 == gmailLabel })?.0 else {
            self = .label(gmailLabel)
            return
        }
        self = label
    }
}
