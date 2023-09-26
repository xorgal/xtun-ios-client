//
//  ConnectView.swift
//  xtun-ios-client
//
//  Created by xorgal on 19/08/2023.
//

import SwiftUI
import UIKit

struct ConnectView: View {
    @EnvironmentObject var model: TunnelViewModel
    @Binding var currentView: CurrentView
    
    var body: some View {
        VStack {
            Spacer()
            
            Image(systemName: model.status == .connected ? "network.badge.shield.half.filled" : "globe")
                .renderingMode(.original)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 180, height: 180)
                .foregroundColor(Color.white)
                .padding()
            
            Text(networkConfig.serverPublicAddress)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Color.white)
                .multilineTextAlignment(.center)
                .padding()
            
            Text(model.status.description)
                .font(.title2)
                .foregroundColor(Color.white)
                .padding()
            
            Spacer()
            
            HStack {
                Spacer()
                
                VPNToggleView()
                
                Spacer()
            }

            Spacer()
            
        }
        .alert(isPresented: $model.fireAlert) {
            Alert(title: Text(model.alertTitle), message: Text(model.alertMessage))
        }
    }
}

struct ConnectView_Previews: PreviewProvider {
    static var previews: some View {
        @StateObject var model = TunnelViewModel()
        @State var currentView: CurrentView = .connectView
        ZStack {
            BackgroundView()
            ConnectView(currentView: $currentView).environmentObject(model)
        }
    }
}
