//
//  GmailSearchExpressionGenerator.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 17.06.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import Foundation

protocol GmailSearchBackupGenerator {
    func makeBackupQuery(with expressions: [String]) -> String
}

final class GmailSearchExpressionGenerator: GmailSearchBackupGenerator {
    func makeBackupQuery(with expressions: [String]) -> String {
        let folderQuery = "in:anywhere"
        let search = expressions.map { "\"\($0)\"" }
        let searchExpressionQuery = search.joined(separator: " OR ")
        return folderQuery + " " + searchExpressionQuery + " has:attachment"
    }
}
