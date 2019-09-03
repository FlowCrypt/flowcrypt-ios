//
//  Retryable.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 8/30/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import RxSwift

extension ObservableType  {
    func retryWhenToken(_ attemtCount: Int = 3) -> Observable<Self.Element> {
        return retryWhen { error in
            return error.flatMap { (someError: Error) -> Observable<Element> in
                switch FCError(someError) {
                case .authentication:
                    UserService.shared.renewAccessToken()
                    return Imap.instance
                        .onNewSession
                        .flatMap { _ -> Observable<Element> in
                            return self.share().retry(attemtCount)
                    }
                default:
                    return Observable.error(someError)
                }
            }

        }
    }
}
