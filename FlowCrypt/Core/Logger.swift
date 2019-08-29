//
//  Logger.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 8/29/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation

struct Logger {
    func log(_ message: String, error: Error?, res: Any?, start: DispatchTime) {
        let errStr = error.map { "\($0)" } ?? ""
        var resStr = "Unknown"
        if res == nil {
            resStr = "nil"
        } else if let data = res as? Data {
            resStr = "Data[\(res != nil ? (data.count < 1204 ? "\(data.count)" : "\(data.count / 1024)k") : "-")]"
        } else if let res = res as? NSArray {
            resStr = "Array[\(res.count)]"
        } else if let res = res as? FoldersContext {
            resStr = "FetchFoldersRes[\(res.folders.count)]"
        }
        print("IMAP \(message) -> \(errStr) \(resStr) \(start.millisecondsSince)ms")
    }

    static func debug(_ id: Int, _ msg: String, value: Any? = nil) { // temporary function while we debug token refreshing
        print("[Imap debug \(id) - \(msg)] \(String(describing: value))")
    }
}
