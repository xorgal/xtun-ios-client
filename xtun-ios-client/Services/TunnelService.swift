//
//  TunnelService.swift
//  xtun-ios-client
//
//  Created by xorgal on 19/08/2023.
//

import Foundation
import NetworkExtension
import SwiftUI

final class TunnelService: ObservableObject {
    @Published private(set) var profile: NETunnelProviderManager?

    static let shared = TunnelService()
    
    private var observer: AnyObject?
    
    private init() {
        observer = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] _ in
                self?.updateProfile()
            }
    }

    func updateProfile() {
        updateProfile { _ in }
    }
    
    func addProfile(_ completion: @escaping (Result<Void, Error>) -> Void) {
        let profile = createProfile()
        profile.saveToPreferences { [weak self] error in
            if let error = error {
                return completion(.failure(error))
            }
            
            // See https://forums.developer.apple.com/thread/25928
            profile.loadFromPreferences { [weak self] error in
                self?.profile = profile
                completion(.success(()))
            }
        }
    }
    
    func removeProfile(_ completion: @escaping (Result<Void, Error>) -> Void) {
        assert(profile != nil, "Profile not found.")
        profile?.removeFromPreferences { error in
            if let error = error {
                return completion(.failure(error))
            }
            self.profile = nil
            completion(.success(()))
        }
    }
    
    func startVPNTunnel(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let profile = profile else {
            let error = XTError.profileNotFound
            return completion(.failure(error))
        }

        if profile.connection.status != .disconnected {
            let error = XTError.alreadyRunning
            return completion(.failure(error))
        }

        do {
            try profile.connection.startVPNTunnel()
            completion(.success(()))
        } catch let error {
            completion(.failure(error))
        }
    }
    
    func stopVPNTunnel(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let profile = profile else {
            let error = XTError.profileNotFound
            completion(.failure(error))
            return
        }
        
        if profile.connection.status == .disconnected {
            let error = XTError.alreadyStopped
            completion(.failure(error))
            return
        }
        
        profile.connection.stopVPNTunnel()
        completion(.success(()))
    }
    
    private func createProfile() -> NETunnelProviderManager {
        let profile = NETunnelProviderManager()
        profile.localizedDescription = "xtun" // This can be profile name set by User
        
        let proto = NETunnelProviderProtocol()
        
        // This must match the bundle identifier of the app extension containing PacketTunnelProvider
        proto.providerBundleIdentifier = "xyz.xorgal.xtun-ios-client.tunnel"
        
        // This must send the actual VPN server address
        proto.serverAddress = networkConfig.serverPublicAddress
        
        // This must send complete NetworkConfig for NEPacketTunnelProvider setup
        proto.providerConfiguration = [
            "NetworkConfig": networkConfig.toDictionary
        ]
        
        // This includes traffic for all networks
        proto.includeAllNetworks = true
        
        // This includes all Cellular services
        proto.excludeCellularServices = false
        
        // Local networks are excluded
        proto.excludeLocalNetworks = true
        
        // APNs excluded
        proto.excludeAPNs = true
        
        // Enforce rotues
        proto.enforceRoutes = true
        
        // Assign protocolConfiguration
        profile.protocolConfiguration = proto
        
        // let onDemandRule = NEOnDemandRuleConnect()
        // onDemandRule.interfaceTypeMatch = .any
        // manager.isOnDemandEnabled = true
        // manager.onDemandRules = [onDemandRule]
        
        // Enable the manager by default
        profile.isEnabled = true
        
        return profile
    }
    
    private func updateProfile(_ completion: @escaping (Result<Void, Error>) -> Void) {
        // Read all of the VPN configurations created by the app that have
        // previously been saved to the Network Extension preferences
        NETunnelProviderManager.loadAllFromPreferences { [weak self] profiles, error in
            guard let self = self else { return }
            
            // There is only one VPN configuration the app provides
            self.profile = profiles?.first
            if let error = error  {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}
