//
//  MessageLabel.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 06.12.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import MailCore

enum MessageLabel: Equatable, Hashable {
    case inbox
    case seen
    case unread
    case starred
    case sent
    case trash
    case draft
    case important
    case none
    case label(String)

    var value: String {
        switch self {
        case let .label(result): return result
        case .unread: return "UNREAD" // Gmail supports UNREAD flag
        case .starred: return "STARRED"
        case .sent: return "SENT"
        case .trash: return "TRASH"
        case .draft: return "DRAFT"
        case .important: return "IMPORTANT"
        case .inbox: return "INBOX"
        // IMAP supports only
        case .seen: return "seen"
        case .none: return "none"
        }
    }
}

// MARK: - IMAP Flags
extension MessageLabel {
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
                self = .none
            } else {
                self = .label(String(imapFlag.rawValue))
            }
        }
    }

    var imapFlagValue: Int {
        switch self {
        case .seen: return MCOMessageFlag.seen.rawValue
        case .starred: return MCOMessageFlag.flagged.rawValue
        case .sent: return MCOMessageFlag.mdnSent.rawValue
        case .trash: return MCOMessageFlag.deleted.rawValue
        case .draft: return MCOMessageFlag.draft.rawValue
        case .label("answered"): return MCOMessageFlag.answered.rawValue
        case .label("forwarded"): return MCOMessageFlag.forwarded.rawValue
        case .label("pending"): return MCOMessageFlag.submitPending.rawValue
        case .label("submited"): return MCOMessageFlag.submitted.rawValue
        case .none: return 0
        default:
            debugPrint("This label \(self) is not supported by this provider")
            return 0
        }
    }
}

// MARK: - GMAIL
extension MessageLabel {
    init(gmailLabel: String) {
        let labels: [MessageLabel] = [.seen, .unread, .starred, .sent, .trash, .draft, .important, .inbox]
        self = labels.first(where: { $0.value == gmailLabel }) ?? .label(gmailLabel)
    }
}
