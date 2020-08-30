//
//  Atman.swift
//  RespectMyAttestation
//
//  Created by David Wagner on 19/08/2020.
//

import SwiftUI
import DeviceCheck
import CryptoKit
import PromiseKit
import PMKFoundation

let root = "http://192.168.86.38:8083"

struct ServerChallenge: Decodable {
    let c: Data
    let id: UUID
}

extension ServerChallenge: CustomStringConvertible {
    var description: String {
        "{ c: \(c.hexDescription); id: \(id.uuidString) }"
    }
}

extension String: Error {}

struct VerifyPacket: Encodable {
    var attestation: Data
    var keyId: String
}


class Atman: ObservableObject {
    
    let session: URLSession
    
    init() {
        let config = URLSessionConfiguration.ephemeral
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        config.timeoutIntervalForRequest = 5
        
        self.session = URLSession(configuration: config)
    }
    
    func go(completion: @escaping (String) -> Void) {
        var messages = ""
        func log(_ message: String) {
            print(message)
            messages += "\n" + message
        }
        func done() {
            completion(messages)
        }
        
        let service = DCAppAttestService.shared
        guard service.isSupported else {
            log("Attestation is not supported")
            done()
            return
        }
        
        if let keyId = getKeyId() {
            log("retrieved keyId: \(keyId)")
            done()
        } else {
            establish(log: log) {
                done()
            }
        }
    }
    
    func generateKey() -> Promise<String> {
        Promise { seal in
            DCAppAttestService.shared.generateKey { (keyId, error) in
                guard error == nil, let keyId = keyId else {
                    seal.reject(error ?? "Failed without error")
                    return
                }
                seal.fulfill(keyId)
            }
        }
    }
    
    func retrieveChallenge(keyId: String) -> Promise<ServerChallenge> {
        let url = URL(string: "\(root)/challenge")!
        return firstly {
            session.dataTask(.promise, with: url)
        }.map {
            let decoder = JSONDecoder()
            return try decoder.decode(ServerChallenge.self, from: $0.data)
        }
    }
    
    func attestKey(challenge: ServerChallenge, keyId: String) -> Promise<Data> {
        Promise { seal in
            let hash = Data(SHA256.hash(data: challenge.c))
            DCAppAttestService.shared.attestKey(keyId, clientDataHash: hash) { (attestation, error) in
                if let error = error {
                    seal.reject(error)
                } else if let attestation = attestation {
                    seal.fulfill(attestation)
                } else {
                    seal.reject("Attest key returned no data and no error")
                }
            }
        }
    }
    
    func verifyKey(attestation: Data, keyId: String) throws -> Promise<String> {
//        log("Got attestation: \(attestation.hexDescription)")
        guard let outurl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("attestation.bin") else {
            throw "Could not create path to write to"
        }
        try attestation.write(to: outurl, options: .atomic)
//        log("Written to \(url.absoluteString)")
        
        
        let url = URL(string: "\(root)/verify")!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpMethod = "POST"

        let v = VerifyPacket(attestation: attestation, keyId: keyId)
        request.httpBody = try JSONEncoder().encode(v)
        
        return firstly {
            session.dataTask(.promise, with: request)
        }.map {
            String(data: $0.data, encoding: .utf8)!
        }
    }
    
    private func establish(log: @escaping (String) -> Void, completion: @escaping () -> Void) {
        firstly {
            self.generateKey()
        }.then { keyId in
            self.retrieveChallenge(keyId: keyId).map { ($0, keyId) }
        }.then { (challenge, keyId) in
            self.attestKey(challenge: challenge, keyId: keyId).map { ($0, keyId) }
        }.then { (attestation, keyId) in
            try self.verifyKey(attestation: attestation, keyId: keyId)
        }.done {
            log("Response from server \($0)")
        }.catch {
            log("Something failed: \($0)")
        }.finally {
            completion()
        }
    }
    
    private static let keyStorageName = "storedKeyID"
    private func store(keyId: String) {
        UserDefaults.standard.set(keyId, forKey: Atman.keyStorageName)
    }
    
    private func getKeyId() -> String? {
        return UserDefaults.standard.string(forKey: Atman.keyStorageName)
    }
    
    func clearKeyId() {
        UserDefaults.standard.removeObject(forKey: Atman.keyStorageName)
    }
}

struct Atman_Previews: PreviewProvider {
    static var previews: some View {
        /*@START_MENU_TOKEN@*/Text("Hello, World!")/*@END_MENU_TOKEN@*/
    }
}
