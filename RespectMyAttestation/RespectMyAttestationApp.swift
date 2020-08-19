//
//  RespectMyAttestationApp.swift
//  RespectMyAttestation
//
//  Created by David Wagner on 19/08/2020.
//

import SwiftUI

@main
struct RespectMyAttestationApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(Atman())
        }
    }
}
