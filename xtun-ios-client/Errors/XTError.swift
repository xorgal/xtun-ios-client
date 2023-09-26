//
//  XTError.swift
//  xtun-ios-client
//
//  Created by xorgal on 25/08/2023.
//

enum XTError: Error {
    case profileNotFound
    case enableProfileFailure
    case alreadyRunning
    case alreadyStopped
    case genericError(String)
    
    var localizedDescription: String {
        switch self {
        case .profileNotFound:
            return "VPN profile not found."
        case .enableProfileFailure:
            return "Failed to enable VPN profile."
        case .alreadyRunning:
            return "Action ignored as VPN tunnel already started."
        case .alreadyStopped:
            return "Action ignored as VPN tunnel already stopped."
        case .genericError(let message):
            return message
        }
    }
}
