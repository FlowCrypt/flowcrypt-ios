//
//  Logger.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 8/29/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation

func log(_ message: String, error: Error?, res: Any?, start: DispatchTime) {
    Logger().log(message, error: error, res: res, start: start)
}

func logDebug(
    _ id: Int?,
    _ msg: String? = nil,
    value: Any? = nil,
    fileName: String = #file,
    functionName: String = #function,
    lineNumber: Int = #line,
    columnNumber: Int = #column
) {
    if let message = msg, let id = id {
        Logger().debug(id, message, value: value)
    } else {
        print("•••• \(fileName) - \(functionName) at line \(lineNumber)[\(columnNumber)]")
    }
}

private struct Logger {
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
        } else if let res = res as? MCOIndexSet {
            resStr = "IndexSet[\(res.count())]"
        }
        print("IMAP \(message) -> \(errStr) \(resStr) \(start.millisecondsSince)ms")
    }

    func debug(_ id: Int, _ msg: String, value: Any? = nil) { // temporary function while we debug token refreshing
         print("[Imap debug \(id) - \(msg)] \(String(describing: value))")
    }
}
