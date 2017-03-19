//
//  LoginController.swift
//  GrubAPI
//
//  Created by Jameson Kirby on 2/8/17.
//
//

import Vapor
import HTTP
import Turnstile
import Auth
import BCrypt

final class LoginController {
    
    func addRoutes(drop: Droplet) {
        let grubapi_v1 = drop.grouped("v1")
        grubapi_v1.post("login", handler: loginUser)
        grubapi_v1.post("register", handler: registerUser)
    }
    
    func registerUser(_ request: Request) throws -> ResponseRepresentable {
        guard let username = request.data["username"]?.string,
            let password = request.data["password"]?.string else {
                throw Abort.custom(status: .badRequest, message: "Failed to parse request")
        }
        
        let credentials: UsernamePassword
        
        do {
            let username_validated: Valid<Count<String>> = try username.validated(by: Count.min(3))
            let password_validated: Valid<Count<String>> = try password.validated(by: Count.min(6))
            credentials = UsernamePassword(username: username_validated.value, password: password_validated.value)
            
        } catch {
            throw Abort.custom(status: .badRequest, message: "Check that username or password meet the character limit requirements")
        }
        
        do {
            guard var user = try User.register(credentials: credentials) as? User else {
                throw Abort.custom(status: .conflict, message: "Failed to register user")
            }
            
            user.username = username
            user.password = try BCrypt.hash(password: password, salt: BCryptSalt(string: salt))
            try user.save()
            let userNode = try Node(node: ["id": user.id, "access_token": user.token, "username": user.username])
            return try JSON(node: ["status": "registered", "user": userNode] )
            
        } catch let error as TurnstileError {
            print(error.description)
            return try JSON(node:["status": error.description])
        }
    }
    
    func loginUser(_ request: Request) throws -> ResponseRepresentable {
        guard let username = request.data["username"]?.string,
            let password = request.data["password"]?.string else {
                throw Abort.badRequest
        }
        
        guard let saltedPassword = try? BCrypt.hash(password: password, salt: BCryptSalt(string: salt)),
            try User.query().filter("username", username).filter("password", saltedPassword).first() != nil else {
                throw Abort.notFound
        }
        
        let credentials = UsernamePassword(username: username, password: saltedPassword)
        
        do {
            let user = try User.authenticate(credentials: credentials) as? User
            guard let authUser = user else {
                throw Abort.custom(status: .expectationFailed, message: "User failed")
            }
            
            let userNode = try Node(node: ["id": authUser.id, "access_token": authUser.token, "username": authUser.username])
            return try JSON(node: ["status": "ok", "user": userNode.makeNode()])
            
        } catch let error {
            throw Abort.custom(status: .expectationFailed, message: error.localizedDescription)
        }
    }

}
