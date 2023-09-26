//
//  UserDefaults+Extension.swift
//  xtun-ios-client
//
//  Created by xorgal on 22/08/2023.
//

import NetworkExtension
import CoreFoundation
import Combine

extension UserDefaults {
    static let group = UserDefaults(suiteName: "group.xyz.xorgal.xtun-ios-client")
    
    @objc dynamic var transportStatus: NEVPNStatus {
        if let statusRawValue = UserDefaults.group?.object(forKey: "transportStatus") as? Int,
           let status = NEVPNStatus(rawValue: statusRawValue) {
            return status
        }
        return .disconnected
    }
    
    @objc dynamic var tunnelLastLogEntry: String? {
        return UserDefaults.group?.string(forKey: "tunnelLastLogEntry")
    }
}
