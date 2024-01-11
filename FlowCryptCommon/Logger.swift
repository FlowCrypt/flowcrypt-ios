//
//  Logger.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 23.04.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
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
// ******* Convenience Usage *******
//
// let logger = Logger.nested(in: Self.self, with: "Flow name")
// logger.logDebug("check is user logged in")
// "⚙️[Flow name][GlobalRouter][23:53:17] check is user logged in"
//
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
public struct Logger {
    private struct Configuration {
        // MARK: - Default logLevel
        static let `default`: Configuration = .init(
            isAll: true,
            logLevel: .warning,
            shouldShowPath: false,
            shouldShowTime: false
        )

        let isAll: Bool
        let logLevel: Logger.Level
        /// Add fupath to message
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
            case .debug: return "⚙️"
            case .info: return "ℹ️"
            case .warning: return "❗️"
            case .error: return "🔥"
            }
        }
    }

    static var dateFormatter = DateFormatter().then {
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
        _ level: Self.Level,
        _ message: String,
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

        // "ℹ️[App Start]"
        if let label {
            messageToPrint.append("\(label)")
        }

        // "ℹ️[App Start][GlobalRouter-proceed-56]"
        if config.shouldShowPath {
            messageToPrint.append("[\(file)-\(function)-\(line)]")
        }

        // "ℹ️[App Start][GlobalRouter-proceed-56][11:25:02]"
        if config.shouldShowTime {
            messageToPrint.append("[\(Self.dateFormatter.string(from: Date()))]")
        }

        messageToPrint.append(" ")
        // "ℹ️[App Start][GlobalRouter-proceed-56][11:25:02] Some message goes here"
        messageToPrint.append(message)

        debugPrint(messageToPrint)
    }
}

// MARK: - Nested
public extension Logger {

    static func nested(_ label: String) -> Logger {
        Logger(config: .default, label: "[\(label)]")
    }

    static func nested(_ type: (some Any).Type) -> Logger {
        Logger(config: .default, label: "[\(String(describing: type))]")
    }

    static func nested(in type: (some Any).Type, with label: String) -> Logger {
        var message = "[\(label)]"
        message.append("[\(String(describing: type))]")
        return Logger(config: .default, label: message)
    }
}

// MARK: - Nested with app label
public extension Logger {
    // MARK: - Log Labels
    enum LogLabels: String {
        /// log all events which is important for app start for a user
        case userAppStart = "App Start"

        /// log all db migration events
        case migration = "Migration"

        /// Core related logs
        case core = "Core"

        /// Setup Flow logs
        case setup = "Setup"
    }

    static func nested(in type: (some Any).Type, with logLabel: LogLabels) -> Logger {
        nested(in: type, with: logLabel.rawValue)
    }
}

// MARK: - Instance
public extension Logger {
    /// verbose messages
    func logVerbose(_ message: String) {
        log(.verbose, message)
    }

    /// default log level to print some information message
    func logInfo(_ message: String) {
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
public extension Logger {
    private static let logger = Logger(config: .default)

    /// verbose messages
    static func logVerbose(_ message: String) {
        logger.log(.verbose, message)
    }

    /// default log level to print some information message
    static func logInfo(_ message: String) {
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
public func print(_ object: Any) {
    // Only allowing in DEBUG mode
    #if DEBUG
        Swift.print(object)
    #endif
}
