//
//  CORS.swift
//  GrubAPI
//
//  Created by Jameson Kirby on 3/22/17.
//
//

import HTTP
import JSON
import Vapor

class CORS: Middleware {
    func respond(to request: Request, chainingTo chain: Responder) throws -> Response {
        let response: Response
        if request.isPreflight {
            response = "".makeResponse()
        } else {
            response = try chain.respond(to: request)
        }
        
        response.headers["Access-Control-Allow-Origin"] = "*";
        response.headers["Access-Control-Allow-Headers"] = "Origin, Content-Type, Accept, Authorization"
        response.headers["Access-Control-Allow-Methods"] = "POST, GET, PUT, OPTIONS, DELETE, PATCH"
        return response
    }
}

extension Request {
    var isPreflight: Bool {
        return method == .options
            && headers["Access-Control-Request-Method"] != nil
    }
}
