//
//  xtunApp.swift
//  xtun-ios-client
//
//  Created by xorgal on 19/08/2023.
//

import SwiftUI

@main
struct xtunApp: App {
    @StateObject var model = TunnelViewModel()
    
    // Configuration files are loaded upon initialization
    // If corresponding file not found it will be created with initial values
    // Usually, that means App was launched for the first time
    init() {
        // AppConfig.json
        if let _appConfig: AppConfig = FileManagerHelper.loadFile() {
            appConfig = _appConfig
        } else {
            FileManagerHelper.saveFile(appConfig)
        }

        // NetworkConfig.json
        if let _networkConfig: NetworkConfig = FileManagerHelper.loadFile() {
            networkConfig = _networkConfig
        } else {
            FileManagerHelper.saveFile(networkConfig)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(model)
        }
    }
}
