//
//  MessagesProvider.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 8/27/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import RxSwift

struct MessageContext {
    let messages: [MCOIMAPMessage]
    let totalMessages: Int
}

protocol MessageProvider {
    func fetchMessages(for folder: String, count: Int, from: Int?) -> Observable<MessageContext>
}

@available(*, deprecated, message: "Refactor using Promises instead of rx")
struct DefaultMessageProvider: MessageProvider {
    private let sessionProvider: Imap
    private let messageProvider: MessageKindProvider

    var session: MCOIMAPSession {
        #warning("Should be fixed")
        return sessionProvider.getImapSess()!
    }

    init(
        sessionProvider: Imap = .instance,
        messageProvider: MessageKindProvider = DefaultMessageKindProvider()
    ) {
        self.sessionProvider = sessionProvider
        self.messageProvider = messageProvider
    }

    func fetchMessages(for folder: String, count: Int, from: Int? = 0) -> Observable<MessageContext> {
        var totalCount = 0
        return folderInfo(for: folder)
            .map {
                let total = Int($0.messageCount)
                totalCount = total
                return total
            }
            .map {
                self.createSet(for: count, total: $0, from: (from ?? 0))
            }
            .flatMap { (set: MCOIndexSet) -> Observable<[MCOIMAPMessage]> in
                let kind = self.messageProvider.imapMessagesRequestKind
                return self.fetchMessagesByNumberOperation(for: folder, kind: kind, set: set)
            }
            .map {
                MessageContext(messages: $0, totalMessages: totalCount)
            }
            .retry(3)
    }
}

extension DefaultMessageProvider {
    private func folderInfo(for path: String) -> Observable<MCOIMAPFolderInfo> {
        return Observable.create { observer in
            self.session
                .folderInfoOperation(path)
                .start { error, folder in
                    if let error = error {
                        observer.onError(FCError(error))
                    }
                    if let folder = folder {
                        observer.onNext(folder)
                        observer.onCompleted()
                    }
                    else {
                        observer.onError(FCError.general)
                    }
            }
            return Disposables.create()
        }
    }

    private func createSet(for numberOfMessages: Int, total: Int, from: Int) -> MCOIndexSet {
        var lenght = numberOfMessages - 1
        if lenght < 0 {
            lenght = 0
        }

        var diff = total - lenght - from
        if diff < 0 {
            diff = 1
        }

        let range = MCORange(location: UInt64(diff), length: UInt64(lenght))

        return MCOIndexSet(range: range)
    }

    private func fetchMessagesByNumberOperation(
        for folder: String,
        kind: MCOIMAPMessagesRequestKind,
        set: MCOIndexSet
        ) -> Observable<[MCOIMAPMessage]> {
        return Observable.create { observer in
            self.session
                .fetchMessagesByNumberOperation(withFolder: folder, requestKind: kind, numbers: set)
                .start { error, messages, set in
                    if let error = error {
                        observer.onError(FCError(error))
                    }
                    if let messages = messages as? [MCOIMAPMessage]  {
                        observer.onNext(messages)
                        observer.onCompleted()
                    }
                    else {
                        observer.onError(FCError.general)
                    }
            }

            return Disposables.create()
        }
    }
}

