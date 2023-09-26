//
//  AppConfig.swift
//  xtun-ios-client
//
//  Created by xorgal on 19/08/2023.
//

struct AppConfig: FileProtocol {
    static var file: String = "AppConfig.json"

    var initialized: Bool
    var deviceRegistered: Bool
}

func createAppConfig() -> AppConfig {
    return appConfig
}

var appConfig = AppConfig(initialized: false, deviceRegistered: false)
