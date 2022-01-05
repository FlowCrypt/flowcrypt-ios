//
//  MultipartDataRequest.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 27/12/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

struct MultipartDataRequest {
    private let lineSeparator = "\r\n"

    let boundary = UUID().uuidString
    let httpBody = NSMutableData()

    init(items: [MultipartDataItem]) {
        items.forEach(append)
        appendBoundary()
    }

    private func append(item: MultipartDataItem) {
        httpBody.append("--\(boundary)\(lineSeparator)")
        httpBody.append("Content-Disposition: form-data; name=\"\(item.name)\"; filename=\"\(item.name)\"\(lineSeparator)")
        httpBody.append("Content-Type: \(item.contentType)\(lineSeparator)\(lineSeparator)")
        httpBody.append(item.data)
        httpBody.append(lineSeparator)
    }

    private func appendBoundary() {
        httpBody.append("--\(boundary)--\(lineSeparator)")
    }
}

struct MultipartDataItem {
    let data: Data
    let name: String
    let contentType: String
}
