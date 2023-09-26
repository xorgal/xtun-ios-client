//
//  MainMenuView.swift
//  xtun-ios-client
//
//  Created by xorgal on 19/08/2023.
//

import SwiftUI

enum CurrentView {
    case onboardingView, connectView, setupView, logsView
}

struct MainMenuView: View {
    @Binding var currentView: CurrentView

    @State private var isMenuOpen: Bool = false

    var body: some View {
        Menu {
            Button(action: {
                currentView = .connectView
            }) {
                Label("Connect", systemImage: "network.badge.shield.half.filled")
            }
            Button(action: {
                currentView = .setupView
            }) {
                Label("Setup", systemImage: "gearshape")
            }
            Button(action: {
                currentView = .logsView
            }) {
                Label("Logs", systemImage: "doc.text.below.ecg")
            }
        } label: {
            Image(systemName: "line.3.horizontal")
                .font(.title)
        }
        .foregroundColor(Color.white)
    }
}
