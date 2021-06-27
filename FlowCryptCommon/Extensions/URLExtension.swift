//
//  URLExtension.swift
//  FlowCryptCommon
//
//  Created by Yevhen Kyivskyi on 24.06.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import Foundation

public extension URL {
    var sharedDocumentURL: URL? {
        guard let scheme = self.scheme else { return nil }
        
        let urlString = self.absoluteString
        let sharedDocumentUrlString = urlString.replacingOccurrences(
            of: scheme,
            with: "shareddocuments"
        )
        
        return URL(string: sharedDocumentUrlString)
    }
}
