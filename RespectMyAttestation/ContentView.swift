//
//  ContentView.swift
//  RespectMyAttestation
//
//  Created by David Wagner on 19/08/2020.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var atman: Atman
    @State var output: String = ""
    
    var body: some View {
        VStack {
            Button ("Reset") {
                atman.clearKeyId()
            }.padding()
            Button("Go") {
                atman.go { (message) in
                    output = message
                }
            }
            Text(output)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewDevice("iPhone 11 Pro Max")
            .environmentObject(Atman())
    }
}
