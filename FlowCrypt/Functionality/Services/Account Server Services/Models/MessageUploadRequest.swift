//
//  MessageUploadRequest.swift
//  FlowCrypt
//
//  Created by Roma Sosnovsky on 27/12/21
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

struct MessageUploadRequest {
    private let boundary: String
    private let lineSeparator = "\r\n"

    let httpBody = NSMutableData()

    init(boundary: String, details: String, content: Data) {
        self.boundary = boundary

        append(details: details)
        append(content: content)

        httpBody.append("--\(boundary)--\(lineSeparator)")
    }

    func append(details: String) {
        httpBody.append("--\(boundary)\(lineSeparator)")
        httpBody.append("Content-Disposition: form-data; name=\"details\"\(lineSeparator)")
        httpBody.append("Content-Type: application/json; charset=utf-8\(lineSeparator)\(lineSeparator)")
        httpBody.append(details)
        httpBody.append(lineSeparator)
    }

    func append(content: Data) {
        httpBody.append("--\(boundary)\(lineSeparator)")
        httpBody.append("Content-Disposition: form-data; name=\"content\"; filename=\"content\"\(lineSeparator)")
        httpBody.append("Content-Type: \"application/octet-stream\"\(lineSeparator)\(lineSeparator)")
        httpBody.append(content)
        httpBody.append(lineSeparator)
    }
}

struct MessageUploadDetails: Encodable {
    let associateReplyToken: String
    let from: String
    let to: [String]
    let cc: [String]
    let bcc: [String]
}

extension Encodable {
    var jsonString: String {
        guard let jsonData = try? JSONEncoder().encode(self),
              let jsonString = String(data: jsonData, encoding: .utf8)
        else { return "" }
        return jsonString
    }
}
