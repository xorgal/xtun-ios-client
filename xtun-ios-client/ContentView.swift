//
//  ContentView.swift
//  xtun-ios-client
//
//  Created by xorgal on 19/08/2023.
//

import SwiftUI

struct ContentView: View {
    @State private var currentView: CurrentView = appConfig.initialized ? .connectView : .onboardingView

    var body: some View {
        ZStack {
            BackgroundView()

            VStack {
                if appConfig.initialized {
                    HStack {
                        MainMenuView(currentView: $currentView)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                    Spacer()
                }

                switch currentView {
                case .onboardingView:
                    OnboardingView(currentView: $currentView)
                case .connectView:
                    ConnectView(currentView: $currentView)
                case .setupView:
                    SetupView(currentView: $currentView)
                case .logsView:
                    LogsView()
                }

                Spacer()

            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        @StateObject var model = TunnelViewModel()
        ContentView().environmentObject(model)
    }
}
