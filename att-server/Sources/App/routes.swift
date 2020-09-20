import Fluent
import Vapor
import CBORCoding

struct C: Codable {
    var id = UUID()
    var c = Data.random(byteCount: 1024)
}

var challenges = [C]()

struct VerifyPacket: Content {
    var attestation: Data
    var keyId: String
}

struct AttestationStatement: Codable {
    var x5c: [Data]
    var receipt: Data
}

struct Attestation: Codable {
    var fmt: String
    var attStmt: AttestationStatement
    var authData: Data
}

func routes(_ app: Application) throws {
    app.get { req in
        return "It works!"
    }

    app.get("hello") { req -> String in
        return "Hello, world!"
    }

    app.get("challenge") { req -> String in
        let c = C()
        challenges.append(c)
        
        let encoder = JSONEncoder()
        let data = try! encoder.encode(c)
        return String(data: data, encoding: .utf8)!
    }

    app.get("challenges") { req -> String in
        let encoder = JSONEncoder()
        let data = try! encoder.encode(challenges)
        return String(data: data, encoding: .utf8)!
    }
    
    app.post("verify") { req -> String in
        let packet = try req.content.decode(VerifyPacket.self)
        
        let decoder = CBORDecoder()
        let item = try! decoder.decode(Attestation.self, from: packet.attestation)
        
        // TODO: Validate x5c certs
        var certs = [SecCertificate]()
        for certData in item.attStmt.x5c {
            let cert = SecCertificateCreateWithData(kCFAllocatorDefault, certData as CFData)!
            certs.append(cert)
        }
        
        let lastChallenge = challenges.last!
        let clientDataHash = SHA256.hash(data: lastChallenge.c)
        let nonce = Data(SHA256.hash(data: item.authData + clientDataHash))
        
        // Horrifically extract nonce to compare as Swift has no sensible ASN.1 parsing
        let oidDict = SecCertificateCopyValues(certs[0], ["1.2.840.113635.100.8.2"] as CFArray, nil) as! [AnyHashable : Any]
        let foo = oidDict["1.2.840.113635.100.8.2"] as! [AnyHashable : Any]
        let bar = foo["value"] as! [Any]
        let baz = bar[1]  as! [AnyHashable : Any]
        let bob = baz["value"] as! Data
        let isValid = bob.dropFirst(bob.count - nonce.count) == nonce
        
        let encoder = JSONEncoder()
        let data = try! encoder.encode(item)
        return String(data: data, encoding: .utf8)!
    }

    try app.register(collection: TodoController())
}
