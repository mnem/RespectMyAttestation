//
//  Atman.swift
//  RespectMyAttestation
//
//  Created by David Wagner on 19/08/2020.
//

import SwiftUI
import DeviceCheck
import CryptoKit


class Atman: ObservableObject {
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
        log("Attestation supported: \(service.isSupported)")
        
        if let keyId = getKeyId() {
            log("retrieved keyId: \(keyId)")
            done()
        } else {
            service.generateKey { keyId, error in
                guard error == nil, let keyId = keyId else {
                    log("generateKey failed: \(String(describing: error))")
                    done()
                    return
                }
                log("generated keyId: \(keyId)")
                
                if let keyIdData = Data(base64Encoded: keyId) {
                    log("keyId base64 decoded length: \(keyIdData.count)")
                    log("keyId base64 bytes: \(keyIdData.hexString)")
                }

                let challenge = Data.random(byteCount: 512)
                let hash = Data(SHA256.hash(data: challenge))
                
                service.attestKey(keyId, clientDataHash: hash) { (attestation, error) in
                    guard error == nil, let attestation = attestation else {
                        log("attestKey failed: \(String(describing: error))")
                        done()
                        return
                    }
                    
                    log("Attestation: \(attestation.hexString)")
                    
                    self.store(keyId: keyId)
                    done()
                }
            }
        }
    }
    
    private static let keyStorageName = "storedKeyID"
    private func store(keyId: String) {
        UserDefaults.standard.set(keyId, forKey: Atman.keyStorageName)
    }
    
    private func getKeyId() -> String? {
        UserDefaults.standard.string(forKey: Atman.keyStorageName)
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
