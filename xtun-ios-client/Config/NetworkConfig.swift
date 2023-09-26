//
//  NetworkConfig.swift
//  xtun-ios-client
//
//  Created by xorgal on 19/08/2023.
//

public struct NetworkConfig: FileProtocol {
    static var file: String = "NetworkConfig.json"

    var deviceId: String
    var serverPublicAddress: String
    var serverLocalIP: String
    var cidr: String
    var key: String
    var mtu: Int
}

extension NetworkConfig {
    var toDictionary: [String: Any] {
        return [
            "deviceId": deviceId,
            "serverPublicAddress": serverPublicAddress,
            "serverLocalIP": serverLocalIP,
            "cidr": cidr,
            "key": key,
            "mtu": mtu
        ]
    }
}

func createNetworkConfig() -> NetworkConfig {
    return networkConfig
}

var networkConfig = NetworkConfig(deviceId: "", serverPublicAddress: "", serverLocalIP: "", cidr: "", key: "", mtu: 1500)
