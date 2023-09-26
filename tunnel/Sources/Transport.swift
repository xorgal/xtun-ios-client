//
//  Transport.swift
//  tunnel
//
//  Created by xorgal on 19/08/2023.
//

import Foundation
import OSLog

// MARK: - TransportProtocol

protocol TransportProtocol {
    
    var delegate: TransportProtocolDelegate? { get set }
    
    func connect()
    func send(text: String)
    func send(data: Data)
    func disconnect()
    func startPingTimer()
    func stopPingTimer()
}

protocol TransportProtocolDelegate: AnyObject {
    func didReceiveData(_ socket: TransportProtocol, didReceive: Data)
    func didReceiveMessage(_ socket: TransportProtocol, didReceive: String)
    func didConnect(_ socket: TransportProtocol)
    func didDisconnect(_ socket: TransportProtocol, _ error: Error?)
    func didReceiveError(_ error: Error?)
}

// MARK: - Transport

class Transport: NSObject, TransportProtocol, URLSessionDelegate, URLSessionWebSocketDelegate {
    
    private var socket: URLSessionWebSocketTask?
    private let timeout: TimeInterval
    private let url: URL
    private let key: String
    private(set) var isConnected = false
    private var pingTimer: DispatchSourceTimer?
    private let pingInterval = 10
    private let log = Logger.transport
    
    weak var delegate: TransportProtocolDelegate?
    
    init(url: URL, key: String, timeout: TimeInterval) {
        self.url = url
        self.key = key
        self.timeout = timeout
        super.init()
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        isConnected = true
        delegate?.didConnect(self)
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        isConnected = false
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            handleError(error)
        }
    }
    
    func connect() {
        let configuration = URLSessionConfiguration.default
        let urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue())
        var urlRequest = URLRequest(url: url, timeoutInterval: timeout)
        urlRequest.setValue(UserAgent, forHTTPHeaderField: "UserAgent")
        urlRequest.addValue(key, forHTTPHeaderField: "key")
        socket = urlSession.webSocketTask(with: urlRequest)
        socket?.resume()
        readMessage()
    }
    
    func send(data: Data) {
        socket?.send(.data(data)) { error in
            self.handleError(error)
        }
    }
    
    func send(text: String) {
        socket?.send(.string(text)) { error in
            self.handleError(error)
        }
    }
    
    private func sendPing() {
        socket?.sendPing(pongReceiveHandler: { error in
            if let error = error {
                self.handleError(error)
            }
        })
    }
    
    func disconnect() {
        socket?.cancel(with: .goingAway, reason: nil)
        delegate?.didDisconnect(self, nil)
    }
    
    func startPingTimer() {
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global())
        timer.schedule(deadline: .now(), repeating: .seconds(10)) // Todo: add to NetworkConfig
        timer.setEventHandler { [weak self] in
            DispatchQueue.global().async {
                self?.sendPing()
            }
        }
        timer.resume()
        pingTimer = timer
        log.post("Started Ping timer with interval: \(self.pingInterval)", logger: log, level: .notice)
    }
    
    func stopPingTimer() {
        pingTimer?.cancel()
        pingTimer = nil
        log.post("Ping timer stopped", logger: log, level: .notice)
    }
    
    private func readMessage() {
        socket?.receive { result in
            switch result {
            case .failure(let error):
                self.delegate?.didReceiveError(error)

            case .success(let message):
                switch message {
                case .data(let data):
                    self.delegate?.didReceiveData(self, didReceive: data)
                case .string(let string):
                    self.delegate?.didReceiveMessage(self, didReceive: string)
                // Unreachable
                @unknown default:
                    return
                }
                self.readMessage()
            }
        }
    }

    private func handleError(_ error: Error?) {
        if let error = error as NSError? {
            if error.code == 57 || error.code == 60 || error.code == 54 {
                isConnected = false
                disconnect()
                // delegate?.didDisconnect(self, error)
            }
        }
    }
}
