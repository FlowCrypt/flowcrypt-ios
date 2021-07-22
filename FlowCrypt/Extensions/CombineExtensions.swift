//
//  CombineExtensions.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 19.07.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import Combine

extension Subscribers.Completion {
    func getError() -> Error? {
        switch self {
        case .failure(let error):
            return error
        case .finished:
            return nil
        }
    }
}
