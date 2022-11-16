//
//  URLExtension.swift
//  FlowCryptCommon
//
//  Created by Yevhen Kyivskyi on 24.06.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import UniformTypeIdentifiers

private let defaultMimeType = "application/octet-stream"

public extension URL {
    var sharedDocumentURL: URL? {
        guard let scheme else { return nil }

        let sharedDocumentUrlString = absoluteString.replacingOccurrences(
            of: scheme,
            with: "shareddocuments"
        )

        return URL(string: sharedDocumentUrlString)
    }

    var mimeType: String {
        UTType(filenameExtension: pathExtension)?.preferredMIMEType ?? defaultMimeType
    }

    var stringWithFilteredTokens: String {
        guard var components = URLComponents(string: absoluteString),
              let queryItems = components.queryItems
        else { return absoluteString }

        components.queryItems = queryItems.map {
            URLQueryItem(name: $0.name, value: $0.name.contains("token") ? "***" : $0.value)
        }

        return components.url?.absoluteString ?? absoluteString
    }
}

extension NSString {
    var mimeType: String {
        UTType(filenameExtension: pathExtension)?.preferredMIMEType ?? defaultMimeType
    }
}

public extension String {
    var mimeType: String {
        (self as NSString).mimeType
    }
}
