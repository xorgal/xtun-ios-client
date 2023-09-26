//
//  TunnelViewModel.swift
//  xtun-ios-client
//
//  Created by xorgal on 25/08/2023.
//

import Foundation
import SwiftUI
import Combine
import NetworkExtension

final class TunnelViewModel: ObservableObject {
    
    // Tunnel state
    @Published private(set) var isEnabled = false
    @Published private(set) var status: NEVPNStatus = .disconnected
    
    // Constants
    @Published private(set) var connectionTimeout = 15
    
    // App State
    @Published var isLoading = false
    @Published var fireAlert = false

    // Alert
    @Published private(set) var alertTitle = ""
    @Published private(set) var alertMessage = ""

    let service: TunnelService
    let log: LogService
    
    private var observers = [AnyObject]()
    private var cancellables = [AnyCancellable]()
    
    init(service: TunnelService = .shared, log: LogService = .shared) {
        self.service = service
        self.log = log
        
        self.refresh()
        
        observers.append(NotificationCenter.default
            .addObserver(forName: .NEVPNStatusDidChange, object: service.profile?.connection, queue: .main) { [weak self] _ in
                self?.refresh()
        })
        
        observers.append(NotificationCenter.default
            .addObserver(forName: .NEVPNConfigurationChange, object: service.profile, queue: .main) { [weak self] _ in
                self?.refresh()
        })
        
        UserDefaults.group?.publisher(for: \.transportStatus).sink { [weak self] in
            self?.status = $0
            self?.log.notice("Status: \($0)", isNEMessage: true)
        }.store(in: &cancellables)
        
        UserDefaults.group?.publisher(for: \.tunnelLastLogEntry).sink { [weak self] in
            if let logEntry = $0 {
                self?.log.notice(logEntry, isNEMessage: true)
            }
        }.store(in: &cancellables)
        
        $isEnabled.sink { [weak self] in
            self?.setEnabled($0)
        }.store(in: &cancellables)
    }

    func handleProfileAdd() {
        service.addProfile() { result in
            switch result {
            case .success:
                self.log.notice("Profile added")
            case .failure(let error):
                self.fireAlert(title: "Failed to add VPN profile", message: error.localizedDescription)
            }
        }
    }
    
    func handleProfileRemove() {
        service.removeProfile() { result in
            switch result {
            case .success:
                self.log.notice("Profile removed")
            case .failure(let error):
                self.fireAlert(title: "Failed to remove VPN profile", message: error.localizedDescription)
            }
        }
    }
    
    func fireAlert(title: String, message: String) {
        self.alertTitle = title
        self.alertMessage = message
        self.fireAlert = true
        self.log.notice("\(title): \(message)")
    }
    
    func composeAlert(title: String, message: String) {
        self.alertTitle = title
        self.alertMessage = message
    }
    
    private func refresh() {
        self.isEnabled = service.profile?.isEnabled ?? false
    }
    
    private func setEnabled(_ isEnabled: Bool) {
        guard isEnabled != service.profile?.isEnabled else { return }
        service.profile?.isEnabled = isEnabled
        saveToPreferences()
    }
    
    private func saveToPreferences() {
        isLoading = true
        guard service.profile != nil else {
            isLoading = false
            self.log.notice("TunnelViewModel: service.profile is nil")
            return
        }
        service.profile?.saveToPreferences { [weak self] error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                if let error = error {
                    self.fireAlert(title: "Failed to update configuration", message: error.localizedDescription)
                    self.alertMessage = error.localizedDescription
                    return
                }
            }
        }
    }
}
