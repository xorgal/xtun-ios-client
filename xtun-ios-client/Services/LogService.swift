//
//  LogService.swift
//  xtun-ios-client
//
//  Created by xorgal on 24/08/2023.
//

import Foundation

import Foundation

final class LogService: ObservableObject {
    
    static let shared = LogService()
    
    struct LogEntry {
        var id: UUID = UUID()
        var timestamp: String
        var message: String
        var isNEMessage: Bool
    }
    
    @Published private(set) var logs: [LogEntry] = []
    
    private let capacity = 1000
    
    init() {
        logs.reserveCapacity(capacity)
    }
    
    private var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yy HH:mm:ss"
        return formatter
    }()
    
    func notice(_ message: String, isNEMessage: Bool = false) {
        let timestamp = timeNow()
        let prefix = isNEMessage ? "NE" : "App"
        let logEntry = LogEntry(timestamp: timestamp, message: message, isNEMessage: isNEMessage)
        removeFirstWhenFull(); logs.append(logEntry)
        print("\(timestamp) [\(prefix)]: \(message)")
    }
    
    private func timeNow() -> String {
        return dateFormatter.string(from: Date())
    }
    
    private func removeFirstWhenFull() {
        guard logs.count >= self.capacity else { return }
        logs.removeFirst()
    }
}

