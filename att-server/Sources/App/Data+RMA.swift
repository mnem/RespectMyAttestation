//
//  Data+RMA.swift
//  RespectMyAttestation
//
//  Created by David Wagner on 19/08/2020.
//

import Foundation

extension Data {
    public var hexString: String {
        self.map { String(format: "%02hhx", $0) } .joined()
    }

    public var hexDescription: String {
        "\(hexString) (\(count) bytes)"
    }

    public static func random(byteCount: Int) -> Data {
      var data = Data(count: byteCount)
      _ = data.withUnsafeMutableBytes {
        SecRandomCopyBytes(kSecRandomDefault, byteCount, $0.baseAddress!)
      }
      return data
    }
}
