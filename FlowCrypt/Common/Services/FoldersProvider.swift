//
//  FoldersProvider.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 8/30/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import RxSwift

struct FoldersContext {
    let folders: [MCOIMAPFolder]
}

protocol FoldersProvider {
    func fetchFolders() -> Observable<FoldersContext>
}

struct DefaultFoldersProvider: FoldersProvider {
    private let sessionProvider: Imap

    var session: MCOIMAPSession {
        #warning("Should be fixed")
        return sessionProvider.getImapSess()!
    }

    init(
        sessionProvider: Imap = .instance
    ) {
        self.sessionProvider = sessionProvider
    }

    func fetchFolders -> Observable<FoldersContext> {
        get().re
    }

    private func get() {
        return Observable.create { observer in
            self.session
                .fetchAllFoldersOperation()?
                .start { error, value in
                    if let error = error {
                        observer.onError(FCError(error))
                    } else if let folders = value as? [MCOIMAPFolder] {
                        observer.onNext(FoldersContext(folders: folders))
                        observer.onCompleted()
                    } else {
                        observer.onError(FCError.general)
                    }
            }

            return Disposables.create()
        }
    }
}
