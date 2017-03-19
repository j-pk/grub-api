//
//  PlaceController.swift
//  GrubAPI
//
//  Created by Jameson Kirby on 1/31/17.
//
//

import Vapor
import HTTP

final class PlaceController: ResourceRepresentable {
    
    func index(request: Request) throws -> ResponseRepresentable {
        return try JSON(node: Place.all().makeNode())
    }
    
    func create(request: Request) throws -> ResponseRepresentable {
        var place = try request.place()
        
        if let service_type = request.data["service_type"]?.int,
        let cost = request.data["cost"]?.int,
        let genre = request.data["genre"]?.int {
            do {
                let service_type_max: Valid<Count<Int>> = try service_type.validated(by: Count.max(6))
                let genre_max: Valid<Count<Int>> = try genre.validated(by: Count.max(5))
                let cost_max: Valid<Count<Int>> = try cost.validated(by: Count.max(4))
                place.cost = cost_max.value
                place.genre = genre_max.value
                place.service_type = service_type_max.value
            } catch {
                throw Abort.custom(status: .badRequest, message: "Value exceeds enum parameters. Check the docs.")
            }
            
            try place.save()
            return place
        }
    
        try place.save()
        return place
    }
    

    
    func show(request: Request, place: Place) throws -> ResponseRepresentable {
        let ratings = try place.ratings().makeNode()
        return try JSON(node: [place, ["ratings": ratings].makeNode()])
    }
    
    func update(request: Request, place: Place) throws -> ResponseRepresentable {
        let updated = try request.place()
        var place = place
        place.name = updated.name
        place.location = updated.location
        place.website_url = updated.website_url
        place.menu_url = updated.menu_url
        place.cost = updated.cost
        place.genre = updated.genre
        place.service_type = updated.service_type
        try place.save()
        return place
    }
    
    func delete(request: Request, place: Place) throws -> ResponseRepresentable {
        try place.delete()
        return JSON([:])
    }
    
    func makeResource() -> Resource<Place> {
        return Resource(
            index: index,
            store: create,
            show: show,
            modify: update,
            destroy: delete
        )
    }
}

extension Request {
    func place() throws -> Place {
        guard let json = json else { throw Abort.badRequest }
        return try Place(node: json)
    }
}
