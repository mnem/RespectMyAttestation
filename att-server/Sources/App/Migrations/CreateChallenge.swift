//
//  File.swift
//  
//
//  Created by David Wagner on 30/08/2020.
//

import Fluent

struct CreateChallenge: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("challenges")
            .id()
            .field("challenge", .data, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("challenges").delete()
    }
}
