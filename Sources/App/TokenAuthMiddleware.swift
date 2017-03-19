//
//  TokenAuthMiddleware.swift
//  GrubAPI
//
//  Created by Jameson Kirby on 2/8/17.
//
//

import Vapor
import HTTP
import Turnstile
import Auth
import VaporJWT

class TokenAuthMiddleware: Middleware {
    public func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        guard let bearer = request.headers["Authorization"], bearer.hasPrefix("Bearer ") else {
            throw Abort.custom(status: .unauthorized, message: "Invalid or expired access token. Reauthenticate.")
        }
        
        let components = bearer.components(separatedBy: " ")
        guard let token = components.last,
            let _ = Authentication().decodeJWT(token) else {
                throw Abort.custom(status: .unauthorized, message: "Failed to decode access token. Reauthenticate.")
        }
        
        return try next.respond(to: request)
    }
}
