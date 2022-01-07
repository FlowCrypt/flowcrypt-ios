//
//  MessageLabel.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 06.12.2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import MailCore

struct MessageLabel: Equatable, Hashable {
    let type: MessageLabelType

    var isLabel: Bool {
        guard case .label = type else {
            return false
        }
        return true
    }
}

enum MessageLabelType: Equatable, Hashable {
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
        case .label(let result): return result
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

extension MessageLabelType {
    var isInbox: Bool {
        guard case .inbox = self else {
            return false
        }
        return true
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

struct ImapMessageFlags: OptionSet {
    let rawValue: Int

    static let test = ImapMessageFlags(rawValue: 0 << 0)
}

// MARK: - GMAIL
extension MessageLabelType {
    init(gmailLabel: String) {
        let types: [MessageLabelType] = [.seen, .unread, .starred, .sent, .trash, .draft, .important]
        let all = types.map { type in
            (type, type.value)
        }
        guard let label = all.first(where: { $0.1 == gmailLabel })?.0 else {
            self = .label(gmailLabel)
            return
        }
        self = label
    }
}
