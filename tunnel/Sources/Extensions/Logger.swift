//
//  Logger+Extension.swift
//  tunnel
//
//  Created by xorgal on 20/08/2023.
//

import OSLog

enum LogLevel {
    case notice, info, debug, warning, error, fault
}

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!
    
    static let tunnel = Logger(subsystem: subsystem, category: "tunnel")
    static let transport = Logger(subsystem: subsystem, category: "transport")
    
    func post(_ message: String, logger: Logger, level: LogLevel, mask: Bool = false) {
        UserDefaults.group?.saveLogEntry(message)

        switch level {
        case .info:
            mask ? logger.info("\(message, privacy: .private)") : logger.info("\(message, privacy: .public)")
        case .debug:
            mask ? logger.debug("\(message, privacy: .private)") : logger.debug("\(message, privacy: .public)")
        case .warning:
            mask ? logger.warning("\(message, privacy: .private)") : logger.warning("\(message, privacy: .public)")
        case .error:
            mask ? logger.error("\(message, privacy: .private)") : logger.error("\(message, privacy: .public)")
        case .fault:
            mask ? logger.fault("\(message, privacy: .private)") : logger.fault("\(message, privacy: .public)")
        case .notice:
            mask ? logger.notice("\(message, privacy: .private)") : logger.notice("\(message, privacy: .public)")
        }
    }
}
