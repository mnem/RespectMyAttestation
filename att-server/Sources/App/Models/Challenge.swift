//
//  File.swift
//  
//
//  Created by David Wagner on 30/08/2020.
//

import Fluent
import Vapor

final class Challenge: Model {
    static let schema = "challenges"
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: "challenge")
    var challenge: Data

    init() { }

    init(id: UUID? = nil, challenge: Data) {
        self.id = id
        self.challenge = challenge
    }
}

extension Challenge: CustomStringConvertible {
    var description: String {
        "{Challenge id: \(id?.uuidString ?? ""); challenge: \(challenge.hexDescription) }"
    }
}
