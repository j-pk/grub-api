//
//  GrubController.swift
//  GrubAPI
//
//  Created by Jameson Kirby on 1/31/17.
//
//

import Vapor
import HTTP
import VaporPostgreSQL
import Foundation

final class GrubController {

    func addRoutes(drop: Droplet) {
        let grubapi_v1 = drop.grouped("v1").grouped(TokenAuthMiddleware())
        grubapi_v1.get("version", handler: version)
        grubapi_v1.post("places/search", handler: search_grub)
        grubapi_v1.get("places/random", handler: random)
        grubapi_v1.post("places/location/search", handler: search_google)
        grubapi_v1.get("places/genre/:id", handler: place_genre)
        grubapi_v1.post("details", handler: place_details)
    }
    
    func version(request: Request) throws -> ResponseRepresentable {
        if let db = drop.database?.driver as? PostgreSQLDriver {
            let db_version = try db.raw("SELECT version()")
            let grubapi_version = try Node(node: ["API Version": "1.0"])
            return try JSON(node: [grubapi_version, db_version])
        } else {
            return "Database Connection Failed"
        }
    }
    //search Grub_DB
    func search_grub(request: Request) throws -> ResponseRepresentable {
        guard let name = request.data["name"]?.string else {
            throw Abort.badRequest
        }
        return try JSON(node: Place.query().filter("name", contains: name).all())
    }
    
    func place_genre(request: Request) throws -> ResponseRepresentable {
        guard let genre = request.parameters["id"]?.int else {
            throw Abort.badRequest
        }
        
        return try JSON(node: Place.query().filter("genre", .equals, genre).all())
    }
    
    //search Google_Places
    func search_google(request: Request) throws -> ResponseRepresentable {
        guard let location_latitude = request.data["latitude"]?.double,
        let location_longitude = request.data["longitude"]?.double,
        var search_radius = request.data["radius"]?.int,
        let search_name = request.data["name"]?.string else {
                throw Abort.custom(status: .badRequest, message: "Latitude, Longitude require double values. Radius requires an int.")
        }
        do {
          search_radius = try search_radius.validated(by: Count.max(50000)).value
        } catch {
            throw Abort.custom(status: .badRequest, message: "Radius exceeds maxium allowed meters")
        }
        
        let place_json = try drop.client.get(google_place_api_url + "nearbysearch/json?",
                                         query: ["location": "\(location_latitude),\(location_longitude)",
                                            "radius": search_radius,
                                            "type": "restaurant",
                                            "keyword": search_name,
                                            "key": key])
        

        
        return try parse_google_json(response: place_json)
    }
    
    func parse_google_json(response: Response) throws -> JSON {
        guard let places = response.data["results"]?.array else {
            throw Abort.custom(status: .badRequest, message: "No results")
        }
        
        var place_array = [Place]()
        
        do {
            try places.forEach({ place in
                guard let name = place.object?["name"]?.string else { throw Abort.custom(status: .expectationFailed, message: "Failed to parse name") }
                guard let location = place.object?["vicinity"]?.string else { throw Abort.custom(status: .expectationFailed, message: "Failed to parse location") }
                let cost = place.object?["price_level"]?.int != nil ? (place.object?["price_level"]?.int)! - 1 : nil
                
                place_array.append(Place.init(name: name, location: location, cost: cost))
            })
        }
        
        return try place_array.makeJSON()
    }
    
    func place_details(request: Request) throws -> ResponseRepresentable {
        guard let place_id = request.data["google_place_id"]?.string else {
            throw Abort.custom(status: .badRequest, message: "Invalid place_id")
        }
        return try drop.client.get(google_place_api_url + "details/json?",
                               query: ["placeid": place_id,
                                "key": key])
        Date().timeIntervalSince1970
    }
    
    func random(request: Request) throws -> ResponseRepresentable {
        let places = try Place.all()
        var randomIndex: Int = 0
        #if os(Linux)
            srandom(UInt32(Date().timeIntervalSince1970))
            randomIndex = Int(random() % places.count)
        #else
            randomIndex = Int(arc4random_uniform(UInt32(places.count)))
        #endif
        return places[randomIndex]
    }
    
}

