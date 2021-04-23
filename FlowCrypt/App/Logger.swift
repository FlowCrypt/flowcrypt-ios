//
//  Logger.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 23.04.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import Foundation

// MARK: - Documentation
//
// ******* To print ALL messages *******
// Change
// Configuration.default isAll = true
//
//
// ******* To print with log level *******
// Change
// Configuration.default isAll = false
// Configuration.default logLevel = (.level)
//
//
// ******* Usage *******
// let logger = Logger.nested("App Start")
// logger.logDebug("some message")
//
//
// ******* OR *******
// Logger.logDebug("some message")
//
// ******* Nested Logger *******
// inside some class
// let logger = Logger.nested(Self.self)
// logger.logWarning("some")

// MARK: - Implementation
struct Logger {
    private struct Configuration {
        static let `default`: Configuration = .init(
            isAll: false,
            logLevel: .debug,
            shouldShowPath: true,
            shouldShowTime: true
        )

        let isAll: Bool
        let logLevel: Logger.Level
        /// Add path to message
        let shouldShowPath: Bool
        /// Add time to message
        let shouldShowTime: Bool
    }

    private enum Level: Equatable, Comparable {
        case verbose
        case info
        case debug
        case error
        case warning

        var label: String {
            switch self {
            case .verbose: return "🏷"
            case .info: return "ℹ️"
            case .debug: return "⚙️"
            case .error: return "❗️"
            case .warning: return "🔥"
            }
        }
    }

    static var dateFormatter =  DateFormatter().then {
        $0.dateFormat = "HH:mm:ss"
        $0.locale = .current
        $0.timeZone = .current
    }

    private let config: Configuration
    private let label: String?

    private init(config: Configuration = .default, label: String? = nil) {
        self.config = config
        self.label = label
    }

    private func log(
        _ level: Logger.Level,
        _ message: @autoclosure () -> String,
        file: String = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        var shouldPrint = false

        if config.isAll {
            shouldPrint = true
        } else {
            shouldPrint = level >= config.logLevel
        }

        guard shouldPrint else { return }

        var messageToPrint = ""

        // "ℹ️"
        messageToPrint.append("\(level.label)")

        // "ℹ️[11:25:02]"
        if config.shouldShowTime {
            messageToPrint.append("[\(Self.dateFormatter.string(from: Date()))]")
        }

        // "ℹ️[11:25:02][App Start]"
        if let label = self.label {
            messageToPrint.append("[\(label)]")
        }

        // "ℹ️[11:25:02][App Start][GlobalRouter-proceed-56]"
        if config.shouldShowPath {
            messageToPrint.append("[\(file)-\(function)-\(line)]")
        }

        messageToPrint.append(" ")
        // "ℹ️[11:25:02][App Start][GlobalRouter-proceed-56] Some message goes here"
        messageToPrint.append(message())

        debugPrint(messageToPrint)
    }
}

// MARK: - Nested
extension Logger {
    static func nested(_ label: String) -> Logger {
        Logger(config: .default, label: label)
    }

    static func nested<T>(_ type: T.Type) -> Logger {
        Logger(config: .default, label: String.init(describing: type))
    }
}

// MARK: - Instance
extension Logger {
    /// verbose messages
    func logVerbose(_ message: String) {
        log(.verbose, message)
    }

    /// default log level to print some information message
    func logInfog(_ message: String) {
        log(.info, message)
    }

    /// debug log level for debugging some issues during development. Consider info log level to any other messages
    func logDebug(_ message: String) {
        log(.debug, message)
    }

    /// log errors only
    func logError(_ message: String) {
        log(.error, message)
    }

    /// log important warings
    func logWarning(_ message: String) {
        log(.warning, message)
    }
}

// MARK: - Static
extension Logger {
    private static let logger = Logger(config: .default)

    /// verbose messages
    static func logVerbose(_ message: String) {
        logger.log(.verbose, message)
    }

    /// default log level to print some information message
    static func logInfog(_ message: String) {
        logger.log(.info, message)
    }

    /// debug log level for debugging some issues during development. Consider info log level to any other messages
    static func logDebug(_ message: String) {
        logger.log(.debug, message)
    }

    /// log errors only
    static func logError(_ message: String) {
        logger.log(.error, message)
    }

    /// log important warings
    static func logWarning(_ message: String) {
        logger.log(.warning, message)
    }
}

// MARK: - print
// By default the print() will print to the console for both release and debug builds.
/// Wrapping Swift.print() inside DEBUG flag
func print(_ object: Any) {
  // Only allowing in DEBUG mode
  #if DEBUG
      Swift.print(object)
  #endif
}

func releasePrint(_ object: Any) {
    Swift.print(object)
}
