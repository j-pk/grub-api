//
//  User.swift
//  GrubAPI
//
//  Created by Jameson Kirby on 2/8/17.
//
//

import Vapor
import Auth
import Turnstile
import VaporJWT
import Foundation

final class User: Model {
    
    var id: Node?
    var exists: Bool = false

    var username: String
    var password: String
    var token: String?
    
    init(username: String, password: String) {
        self.id = nil
        self.username = username
        self.password = password
    }
    
    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        username = try node.extract("username")
        password = try node.extract("password")
        token = try node.extract("token")
    }
    
    init(credentials: UsernamePassword) {
        self.username = credentials.username
        self.password = credentials.password
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
                        "id": id,
                        "username": username,
                        "password": password,
                        "token": token
                        ])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create("users") { users in
            users.id()
            users.string("username")
            users.string("password")
            users.string("token", optional: true)
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete("users")
    }
    
}

struct Authentication {
    static let AccessTokenSigningKey = "secret"
    
    static func generateExpirationDate() -> Date {
        return Date() + (60 * 5) // 5 Minutes later
    }
    
    func decodeJWT(_ token: String) -> JWT? {
        guard let jwt = try? JWT(token: token),
            let _ = try? jwt.verifySignatureWith(HS256(key: Authentication.AccessTokenSigningKey.makeBytes())) else  {
                return nil
        }
        return jwt
    }
}

extension User: Auth.User {
    
    static func authenticate(credentials: Credentials) throws -> Auth.User {
        var user: User?
        
        switch credentials {
        case let userNamePassword as UsernamePassword:
            let fetchedUser = try User.query().filter("username", userNamePassword.username).first()
            guard let user = fetchedUser else {
                throw Abort.custom(status: .networkAuthenticationRequired, message: "User does not exist")
            }
            if userNamePassword.password == user.password {
                return user
            } else {
                throw Abort.custom(status: .networkAuthenticationRequired, message: "Invalid user name or password")
            }
        case let id as Identifier:
            guard let user = try User.find(id.id) else {
                throw Abort.custom(status: .forbidden, message: "Invalid user id")
            }
            return user
        case let accessToken as AccessToken:
            user = try User.query().filter("token", accessToken.string).first()
            
        default:
            throw IncorrectCredentialsError()
        }
        
        if var user = user {
            // Check if we have an accessToken first, if not, lets create a new one
            if let accessToken = user.token {
                // Check if our authentication token has expired, if so, lets generate a new one as this is a fresh login
                let receivedJWT = try JWT(token: accessToken)
                
                // Validate it's time stamp
                if !receivedJWT.verifyClaims([ExpirationTimeClaim()]) {
                    try user.generateToken()
                }
            } else {
                // We don't have a valid access token
                try user.generateToken()
            }
            
            try user.save()
            
            return user
        } else {
            throw IncorrectCredentialsError()
        }
    }
    
    static func register(credentials: Credentials) throws -> Auth.User {
        var newUser: User
        
        switch credentials {
        case let credentials as UsernamePassword:
            newUser = User(credentials: credentials)
            
        default: throw UnsupportedCredentialsError()
        }
        
        if try User.query().filter("username", newUser.username).first() == nil {
            try newUser.generateToken()
            try newUser.save()
            return newUser
        } else {
            throw AccountTakenError()
        }
    }
    
    func generateToken() throws {
        let payload = Node.object(["username": .string(username),
                                   "expires" : .number(.double(Authentication.generateExpirationDate().timeIntervalSinceReferenceDate))])
        let jwt = try JWT(payload: payload, signer: HS256(key: Authentication.AccessTokenSigningKey.makeBytes()))
        self.token = try jwt.createToken()
    }
    
    
    func validateToken() throws -> Bool {
        guard let token = self.token else { return false }
        // Validate our current access token
        let receivedJWT = try JWT(token: token)
        if try receivedJWT.verifySignatureWith(HS256(key: Authentication.AccessTokenSigningKey.makeBytes())) {
            // If we need a new token, lets generate one
            if !receivedJWT.verifyClaims([ExpirationTimeClaim()]) {
                try self.generateToken()
                return true
            }
        }
        return false
    }
    
}


