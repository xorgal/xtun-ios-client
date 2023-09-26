//
//  UserDefaults+Extension.swift
//  tunnel
//
//  Created by xorgal on 22/08/2023.
//

import NetworkExtension

extension UserDefaults {
    static let group = UserDefaults(suiteName: "group.xyz.xorgal.xtun-ios-client")
    
    func saveTransportStatus(_ status: NEVPNStatus) {
        UserDefaults.group?.set(status.rawValue, forKey: "transportStatus")
        usleep(10000)
    }
    
    func saveLogEntry(_ logEntry: String) {
        UserDefaults.group?.set(logEntry, forKey: "tunnelLastLogEntry")
        usleep(10000)
    }
}
