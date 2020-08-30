import Fluent
import FluentSQLiteDriver
import Vapor

// configures your application
public func configure(_ app: Application) throws {
    app.http.server.configuration.hostname = "0.0.0.0"
    app.http.server.configuration.port = 8083
    
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

//    app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
    app.databases.use(.sqlite(.memory), as: .sqlite)

//    app.migrations.add(CreateTodo())
    app.migrations.add(CreateChallenge())

    // register routes
    try routes(app)
}
