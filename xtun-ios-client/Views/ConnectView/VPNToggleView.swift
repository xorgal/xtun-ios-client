//
//  VPNToggleView.swift
//  xtun-ios-client
//
//  Created by xorgal on 19/08/2023.
//

import NetworkExtension
import SwiftUI

enum VPNToggleUIState {
    case idle
    case processing
}

// Todo: Currently if VPN connection was lost and client is trying to reconnect Toggle button is disabled
// That means, the only option to switch VPN off is from device settings
// Change behavior to turn VPN off if button is tapped during reconnection

struct VPNToggleView: View {
    @EnvironmentObject var model: TunnelViewModel
    
    @State private var isOn: Bool = false
    @State private var uiState: VPNToggleUIState = .idle
    @State private var isProcessingToggleAction: Bool = false

    var body: some View {
        HStack {
            Toggle("", isOn: $isOn)
                .toggleStyle(VPNToggleConfiguration(loading: uiState == .processing, status: model.status, onToggle: handleToggle))
                .fixedSize()
                .scaleEffect(1.25)
        }
        .onChange(of: model.status, perform: { value in
            switch value {
            case .connected:
                isOn = true
                uiState = .idle
            case .disconnected:
                isOn = false
                uiState = .idle
            case .disconnecting, .reasserting:
                isOn = false
            default:
                break
            }
        })
        .onAppear {
            switch model.status {
            case .connected:
                isOn = true
                uiState = .idle
            case .disconnected:
                isOn = false
                uiState = .idle
            case .disconnecting, .reasserting:
                isOn = false
                uiState = .processing
            default:
                break;
            }
        }
    }

    private func handleToggle() {
        print("handleToggle: isOn: \(isOn), uiState: \(uiState), isProcessingToggleAction: \(isProcessingToggleAction)")
        
        guard !isProcessingToggleAction else { return }
        
        isProcessingToggleAction = true
        
        uiState = .processing
        if isOn {
            guard model.status == .connected else {
                isOn = false
                return
            }
            handleStopVPNTunnel()
        } else {
            guard model.status == .disconnected else {
                isOn = true
                return
            }
            handleStartVPNTunnel()
        }
    }
    
    private func handleStartVPNTunnel() {
        Task {
            do {
                if model.service.profile?.isEnabled != true {
                    model.service.profile?.isEnabled = true
                    try await model.service.profile?.saveToPreferences()
                }
                model.service.startVPNTunnel() { result in
                    defer { isProcessingToggleAction = false }
                    switch result {
                    case .success:
                        model.log.notice("Starting VPN tunnel. Status update pending.")
                        checkVPNStatusForConnection(timeout: Int(model.connectionTimeout))
                    case .failure(let error):
                        self.isOn = model.status == .connected ? true : false
                        self.uiState = .idle
                        self.isProcessingToggleAction = false
                        model.fireAlert(title: "Failed to start VPN tunnel", message: error.localizedDescription)
                    }
                }
            } catch let error {
                self.model.fireAlert(title: "Failed to start VPN tunnel", message: error.localizedDescription)
            }
        }
    }

    private func handleStopVPNTunnel() {
        Task {
            do {
                if model.service.profile?.isEnabled != true {
                    model.service.profile?.isEnabled = true
                    try await model.service.profile?.saveToPreferences()
                }
                model.service.stopVPNTunnel() { result in
                    defer { isProcessingToggleAction = false }
                    switch result {
                    case .success:
                        model.log.notice("Stopping VPN tunnel. Status update pending.")
                    case .failure(let error):
                        self.isOn = model.status == .connected ? true : false
                        self.uiState = .idle
                        self.isProcessingToggleAction = false
                        model.fireAlert(title: "Failed to stop VPN tunnel", message: error.localizedDescription)
                    }
                }
            } catch let error {
                self.model.fireAlert(title: "Failed to stop VPN tunnel", message: error.localizedDescription)
            }
        }
    }


    private func checkVPNStatusForConnection(timeout: Int) {
        var counter = timeout
        
        _ = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if counter == 0 {
                model.fireAlert(title: "Failed to start VPN tunnel", message: "Connection attempt to remote host was unsuccessful and timed out.")
                handleStopVPNTunnel()
                timer.invalidate()
                return
            }
            
            if model.status == .connected {
                timer.invalidate()
                return
            }
            
            if model.status == .invalid {
                model.fireAlert(title: "Failed to start VPN tunnel", message: "Connection attempt to remote host was unsuccessful.")
                handleStopVPNTunnel()
                timer.invalidate()
                return
            }
            
            counter -= 1
        }
    }
}

struct VPNToggleConfiguration: ToggleStyle {
    var loading: Bool
    var status: NEVPNStatus
    var onToggle: (() -> Void)?
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            Button(action: {
                onToggle?()
            }) {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.white.opacity(0.25))
                    .frame(width: 80, height: 40)
                    .overlay(
                        Group {
                            if loading || status == .reasserting {
                                ActivityIndicatorView(count: 5)
                                    .frame(width: 25, height: 25)
                                    .offset(x: -19)
                                    .foregroundColor(.orange)
                            } else {
                                Circle()
                                    .fill(fillColor(for: status))
                                    .padding(.all, 5)
                                    .offset(x: offset(for: status))
                            }
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(lineWidth: 4)
                            .foregroundColor(borderColor(for: status))
                    )
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: status)
            }
            .disabled(loading)
        }
    }
        
        func offset(for status: NEVPNStatus) -> CGFloat {
            switch status {
            case .connected:
                return 19
            case .disconnected, .disconnecting, .reasserting:
                return -19
            default:
                return -19
            }
        }

        func fillColor(for status: NEVPNStatus) -> Color {
            switch status {
            case .connected:
                return Color(red: 57/255, green: 255/255, blue: 20/255)
            case .disconnected:
                return .white
            default:
                return .white
            }
        }
    
    func borderColor(for status: NEVPNStatus) -> Color {
        
        guard !loading else {
            return .orange
        }
        
        switch status {
        case .connected:
            return Color(red: 57/255, green: 255/255, blue: 20/255)
        case .disconnected:
            return .white
        case .disconnecting, .reasserting:
            return .orange
        default:
            return .white
        }
    }
}


struct VPNToggle_Previews: PreviewProvider {
    static var previews: some View {
        return ZStack {
            @StateObject var model = TunnelViewModel()
            BackgroundView()
            VPNToggleView().environmentObject(model)
        }
    }
}
