//
//  FileManagerHelper.swift
//  xtun-ios-client
//
//  Created by xorgal on 19/08/2023.
//

import Foundation

protocol FileProtocol: Codable {
    static var file: String { get }
}

struct FileManagerHelper {

    static func saveFile<T: FileProtocol>(_ object: T) {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let filePath = documentsDirectory.appendingPathComponent(T.file)

        let encoder = JSONEncoder()

        do {
            let data = try encoder.encode(object)
            try data.write(to: filePath)
        } catch {
            print("Error saving \(T.file): \(error)")
        }
    }

    static func loadFile<T: FileProtocol>() -> T? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let filePath = documentsDirectory.appendingPathComponent(T.file)

        if let data = try? Data(contentsOf: filePath) {
            let decoder = JSONDecoder()
            do {
                let object = try decoder.decode(T.self, from: data)
                return object
            } catch {
                print("Error decoding \(T.file): \(error)")
            }
        }
        return nil
    }
}
