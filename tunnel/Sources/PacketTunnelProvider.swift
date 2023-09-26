//
//  PacketTunnelProvider.swift
//  tunnel
//
//  Created by xorgal on 19/08/2023.
//

import NetworkExtension
import OSLog

enum TransportState: String, Codable {
    case connected
    case disconnected
    case reconnecting
}

struct TunnelNetworkConfig {
    var deviceId: String
    var serverPublicAddress: String
    var serverLocalIP: String
    var cidr: String
    var key: String
    var mtu: Int
}

class PacketTunnelProvider: NEPacketTunnelProvider {
    
    private var transport: TransportProtocol?
    private var shouldHandlePackets = false
    private var shouldReconnectTransport = false
    private var reconnectAttempts = 0
    private var reconnectTimer: DispatchSourceTimer?
    private let connectionTimeout = 15.0
    private let log = Logger.tunnel
    
    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        // Notify App immediately
        UserDefaults.group?.saveTransportStatus(.connecting)
        
        // Extract the configuration
        guard let proto = self.protocolConfiguration as? NETunnelProviderProtocol,
              let serverAddress = proto.serverAddress,
              let url = URL(string: "wss://\(serverAddress)/ws") else {
            completionHandler(NSError(domain: NEVPNErrorDomain, code: NEVPNError.configurationInvalid.rawValue, userInfo: nil))
            return
        }
        
        // Extract the NetworkConfig from the providerConfiguration
        if let configDictionary = proto.providerConfiguration?["NetworkConfig"] as? [String: AnyObject],
           let networkConfig = parseNetworkConfig(from: configDictionary) {
            let tunnelSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: networkConfig.serverLocalIP)
            log.post("Received network configuration:\nDevice Id: \(networkConfig.deviceId)\nServer address: \(networkConfig.serverPublicAddress)\nServer local IP: \(networkConfig.serverLocalIP)\nCIDR: \(networkConfig.cidr)\nMTU: \(networkConfig.mtu)", logger: log, level: .notice)
            
            // Define DNS settings
            let dnsSettings = NEDNSSettings(servers: [networkConfig.serverLocalIP])
            dnsSettings.matchDomains = [""] // This matches all domain names.
            tunnelSettings.dnsSettings = dnsSettings
            log.post("DNS settings: \(dnsSettings.servers)", logger: log, level: .notice)
            
            // Define IPv4 settings
            if let clientIPv4Info = parseCIDR(networkConfig.cidr) {
                let ipv4Settings = NEIPv4Settings(addresses: [clientIPv4Info.ip], subnetMasks: [clientIPv4Info.netmask])
                tunnelSettings.ipv4Settings = ipv4Settings
                log.post("Client IPv4: \(clientIPv4Info.ip), netmask: \(clientIPv4Info.netmask)", logger: log, level: .notice)
            }
            
            // Configure MTU
            tunnelSettings.mtu = NSNumber(value: networkConfig.mtu)
            log.post("MTU: \(tunnelSettings.mtu?.stringValue ?? "Unknown")", logger: log, level: .notice)
            
            // Applying the network settings to the tunnel
            self.setTunnelNetworkSettings(tunnelSettings) { (error) in
                if let error = error {
                    self.log.post("Failed to cast setTunnelNetworkSettings: \(error.localizedDescription)", logger: self.log, level: .error)
                    completionHandler(error)
                    return
                }
            }
            
            // Initialize and configure the Transport
            self.transport = Transport(url: url, key: networkConfig.key, timeout: self.connectionTimeout)
            self.transport?.delegate = self
            self.transport?.connect()
            
            self.shouldReconnectTransport = true
            
            completionHandler(nil)
        } else {
            completionHandler(NSError(domain: NEVPNErrorDomain, code: NEVPNError.configurationInvalid.rawValue, userInfo: nil))
        }
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        // Notify App immediately
        UserDefaults.group?.saveTransportStatus(.disconnecting)
        
        self.shouldReconnectTransport = false
        transport?.disconnect()
        transport = nil
        log.post("Tunnel stopped", logger: log, level: .notice)
        
        completionHandler()
    }
    
    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        // Here we can handle messages from the containing app, if needed
        // Just forwarding the same message back for now
        if let handler = completionHandler {
            handler(messageData)
        }
    }
    
    override func sleep(completionHandler: @escaping () -> Void) {
        // Todo: Implement
        completionHandler()
    }
    
    override func wake() {
        // Todo: Implement
    }
    
    private func parseNetworkConfig(from dictionary: [String: AnyObject]) -> TunnelNetworkConfig? {
        // Ensure all necessary properties are present before creating and returning the configuration
        guard let deviceId = dictionary["deviceId"] as? String,
              let serverPublicAddress = dictionary["serverPublicAddress"] as? String,
              let serverLocalIP = dictionary["serverLocalIP"] as? String,
              let cidr = dictionary["cidr"] as? String,
              let key = dictionary["key"] as? String,
              let mtu = dictionary["mtu"] as? Int else {
            log.post("Failed to parse Network Config", logger: log, level: .error)
            return nil
        }
        
        return TunnelNetworkConfig(deviceId: deviceId,
                                   serverPublicAddress: serverPublicAddress,
                                   serverLocalIP: serverLocalIP,
                                   cidr: cidr,
                                   key: key,
                                   mtu: mtu)
    }
    
    func parseCIDR(_ cidr: String) -> (ip: String, netmask: String)? {
        let components = cidr.split(separator: "/")
        
        guard components.count == 2,
              let ip = components.first,
              let maskInt = Int(components[1]),
              maskInt >= 0, maskInt <= 32 else {
            log.post("Failed to parse CIDR", logger: log, level: .error)
            return nil
        }
        
        let binaryString = String(repeating: "1", count: maskInt) +
        String(repeating: "0", count: 32 - maskInt)
        
        var netmaskComponents: [Int] = []
        for index in stride(from: 0, to: 32, by: 8) {
            let start = binaryString.index(binaryString.startIndex, offsetBy: index)
            let end = binaryString.index(start, offsetBy: 8)
            let byteString = binaryString[start..<end]
            
            let byte = strtol(String(byteString), nil, 2)
            netmaskComponents.append(Int(byte))
        }
        
        let netmask = netmaskComponents.map { String($0) }.joined(separator: ".")
        return (String(ip), netmask)
    }
}

// MARK: - Extension

extension PacketTunnelProvider: TransportProtocolDelegate {
    func didReceiveData(_ socket: TransportProtocol, didReceive data: Data) {
        // Write the received data to the utun interface
        self.packetFlow.writePackets([data], withProtocols: [AF_INET as NSNumber]) // Assuming IPv4 here
    }
    
    func didReceiveMessage(_ socket: TransportProtocol, didReceive text: String) {
        // Should not receive any textual messages
        if text == "pong" {
            log.post("\(text)", logger: log, level: .notice)
        }
    }
    
    func didConnect(_ socket: TransportProtocol) {
        cancelReconnectAttempt()
        reconnectAttempts = 0
        transport?.startPingTimer()
        shouldHandlePackets = true
        handlePackets()
        UserDefaults.group?.saveTransportStatus(.connected)
        log.post("Transport connected: handling of packets started".description, logger: log, level: .notice)
    }
    
    func didDisconnect(_ socket: TransportProtocol, _ error: Error?) {
        self.transport?.stopPingTimer()
        shouldHandlePackets = false
        UserDefaults.group?.saveTransportStatus(.disconnected)
        log.post("Transport disconnected: handling of packets stopped".description, logger: log, level: .notice)
        
        guard shouldReconnectTransport else { return }
        
        UserDefaults.group?.saveTransportStatus(.reasserting)
        reconnectTransport()
    }
    
    func didReceiveError(_ error: Error?) {
        // Handle errors. Depending on the error, we might stop the tunnel or attempt a reconnection
        let errorMessage = error?.localizedDescription ?? "Unknown error"
        log.post("Transport error: \(errorMessage)", logger: log, level: .error)
    }
    
    private func reconnectTransport() {
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global())
        timer.schedule(deadline: .now(), repeating: .seconds(Int(self.connectionTimeout))) // Todo: add to NetworkConfig
        timer.setEventHandler { [weak self] in
            DispatchQueue.global().sync {
                self?.reconnectAttempts += 1
                self?.log.post("Reconnecting transport (\(self!.reconnectAttempts))...", logger: Logger.tunnel, level: .notice)
                self?.transport?.connect()
            }
        }
        timer.resume()
        reconnectTimer = timer
    }
    
    private func cancelReconnectAttempt() {
        reconnectTimer?.cancel()
        reconnectTimer = nil
    }
    
    
    private func handlePackets() {
        guard shouldHandlePackets else { return }
        
        self.packetFlow.readPackets { packets, protocols in
            for packet in packets {
                self.transport?.send(data: packet)
            }
            
            // Continue reading packets
            self.handlePackets()
        }
    }
}
