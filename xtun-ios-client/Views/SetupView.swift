//
//  SetupView.swift
//  xtun-ios-client
//
//  Created by xorgal on 19/08/2023.
//

import Foundation
import SwiftUI
import Combine

struct RegisterDeviceRequest: Codable {
    let id: String
}

struct RegisterDeviceResponse: Codable {
    let server: String
    let client: String
}

struct ApiError: Codable {
    let message: String
}

struct SetupView: View {
    @EnvironmentObject var model: TunnelViewModel
    
    @Binding var currentView: CurrentView

    @State private var serverAddress = networkConfig.serverPublicAddress
    @State private var key = networkConfig.key

    @State private var isKeyVisible = false

    @State private var cancellables: Set<AnyCancellable> = []

    var body: some View {
        VStack {
            Spacer()

            Image(systemName: "gearshape")
                .renderingMode(.original)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 180, height: 180)
                .foregroundColor(Color.white)
                .padding()
            Text("VPN Settings")
                .font(.largeTitle)
                .foregroundColor(.white)
                .bold()
                .padding()
            TextField("Server address", text: $serverAddress)
                .padding()
                .frame(width: 300, height: 50)
                .background(Color.gray.opacity(0.5))
                .foregroundColor(.white)
                .font(.title3)
                .bold()
                .cornerRadius(10)
                .border(.red, width: CGFloat(0))
            HStack {
                renderKeyField()
                    .padding()
                    .frame(width: 300, height: 50)
                    .background(Color.gray.opacity(0.5))
                    .foregroundColor(.white)
                    .font(.title3)
                    .bold()
                    .cornerRadius(10)
                    .border(.red, width: CGFloat(0))
            }

            Spacer()

            Button {
                if validateFields() {
                    model.isLoading = true
                    
                    guard let url = URL(string: "https://\(serverAddress)/allocator/register") else {
                        model.fireAlert(title: "Invalid URL", message: "Please check server address and try again")
                        return
                    }

                    let id = UUID().uuidString
                    let request = RegisterDeviceRequest(id: id)

                    let encoder = JSONEncoder()

                    guard let requestPayload = try? encoder.encode(request) else {
                        model.fireAlert(title: "Failed to encode", message: "Failed to encode request data.")
                        return
                    }

                    var urlRequest = URLRequest(url: url)
                    urlRequest.httpMethod = "POST"
                    urlRequest.httpBody = requestPayload
                    urlRequest.setValue(UserAgent, forHTTPHeaderField: "User-Agent")
                    urlRequest.addValue(key, forHTTPHeaderField: "key")
                    urlRequest.addValue("application/json",forHTTPHeaderField: "Content-Type")
                    URLSession.shared.dataTaskPublisher(for: urlRequest)
                        .tryMap { data, response in
                            guard let httpResponse = response as? HTTPURLResponse else {
                                throw URLError(.badServerResponse)
                            }
                            if httpResponse.statusCode == 200 {
                                return data
                            } else {
                                do {
                                    let decoder = JSONDecoder()
                                    let errorResponse = try decoder.decode(ApiError.self, from: data)
                                    throw NSError(domain: serverAddress, code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorResponse.message])
                                } catch {
                                    throw error // Rethrow the original decoding error
                                }
                            }
                        }
                        .receive(on: DispatchQueue.main)
                        .sink { completion in
                            model.isLoading = false
                            switch completion {
                            case .finished:
                                break
                            case .failure(let error):
                                model.fireAlert(title: "Error", message: error.localizedDescription == "not permitted" ? "Invalid API key." : error.localizedDescription)
                            }
                        } receiveValue: { responseData in
                            do {
                                // Decode RegisterDeviceResponse
                                let decoder = JSONDecoder()
                                let response = try decoder.decode(RegisterDeviceResponse.self, from: responseData)

                                // Update network configuration
                                networkConfig.serverPublicAddress = serverAddress
                                networkConfig.key = key
                                networkConfig.deviceId = id
                                networkConfig.serverLocalIP = response.server
                                networkConfig.cidr = response.client
                                
                                // Add VPN configuration profile
                                model.handleProfileAdd()

                                // Update application state
                                appConfig.initialized = true
                                appConfig.deviceRegistered = true
                                
                                // Save configurations to file
                                FileManagerHelper.saveFile(networkConfig)
                                FileManagerHelper.saveFile(appConfig)

                                // Setup completed, render Connect view
                                currentView = .connectView

                            } catch {
                                print("Error:", error.localizedDescription)
                            }
                        }
                        .store(in: &cancellables)


                } else {
                    model.fireAlert = true
                }
            } label: {
                if model.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .foregroundColor(.white)
                            .padding()
                } else {
                    Text("Add VPN Profile")
                        .frame(width: 280, height: 50)
                        .background(Color.white)
                        .foregroundColor(.cyan)
                        .font(.system(size: 20, weight: .bold, design: .default))
                        .cornerRadius(10)
                }
            }
            .disabled(model.isLoading)

            Spacer()
        }
        .onAppear {
            model.service.updateProfile()
        }
        .alert(isPresented: $model.fireAlert) {
            Alert(title: Text(model.alertTitle), message: Text(model.alertMessage))
        }
    }

    private func validateFields() -> Bool {
        if serverAddress.isEmpty || key.isEmpty {
            model.composeAlert(title: "Oops!", message: "All fields must be complete.")
            return false
        }

        return true
    }

    private func renderKeyField() -> some View {
        HStack {
            if isKeyVisible {
                TextField("API key", text: $key)
            } else {
                SecureField("API key", text: $key)
            }
            Button(action: {
                isKeyVisible.toggle()
            }) {
                Image(systemName: isKeyVisible ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.white)
            }
        }
    }
}

struct SetupView_Previews: PreviewProvider {
    static var previews: some View {
        @StateObject var model = TunnelViewModel()
        @State var currentView: CurrentView = .setupView
        ZStack {
            BackgroundView()
            SetupView(currentView: $currentView).environmentObject(model)
        }
    }
}



