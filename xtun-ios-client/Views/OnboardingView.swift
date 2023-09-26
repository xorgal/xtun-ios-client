//
//  OnboardingView.swift
//  xtun-ios-client
//
//  Created by xorgal on 19/08/2023.
//

import SwiftUI

struct OnboardingView: View {
    @Binding var currentView: CurrentView

    var body: some View {
        VStack {
            Spacer()

            Image(systemName: "globe")
                .renderingMode(.original)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 180, height: 180)
                .foregroundColor(Color.white)
                .padding()
            Text("Welcome to xtun VPN")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(Color.white)
                .multilineTextAlignment(.center)
                .padding()
            Text("Connect your iPhone to Virtual Private Network (VPN) over WebSocket")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(Color.white)
                .multilineTextAlignment(.center)
            Spacer()

            Button {
                currentView = .setupView
            } label: {
                Text("Setup Device")
                    .frame(width: 280, height: 50)
                    .background(Color.white)
                    .foregroundColor(.cyan)
                    .font(.system(size: 20, weight: .bold, design: .default))
                    .cornerRadius(10)
            }
            Spacer()
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        @State var currentView: CurrentView = .connectView
        ZStack {
            BackgroundView()
            OnboardingView(currentView: $currentView)
        }
    }
}
