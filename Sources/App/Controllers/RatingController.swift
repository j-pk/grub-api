//
//  RatingController.swift
//  GrubAPI
//
//  Created by Jameson Kirby on 1/31/17.
//
//

import Vapor
import HTTP
import Foundation

final class RatingController: ResourceRepresentable {
    
    func index(request: Request) throws -> ResponseRepresentable {
        return try JSON(node: Rating.all().makeNode())
    }
    
    func create(request: Request) throws -> ResponseRepresentable {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        let stringDate: String = formatter.string(from: Date())
        
        guard let username = request.data["username"]?.string else {
           throw Abort.badRequest
        }
        
        let user = try User.query().filter("username", .equals, username).first()

        if let service = request.data["service"]?.int,
            let food = request.data["food"]?.int  {
            let service_max: Valid<Count<Int>> = try service.validated(by: Count.max(4))
            let food_max: Valid<Count<Int>> = try food.validated(by: Count.max(4))
            
            var rating = try request.rating()
            rating.service = service_max.value
            rating.food = food_max.value
            rating.date_rated = stringDate
            rating.user_id = user?.id
            try rating.save()
            try apply_average_rating(rating: rating)
            return rating
        }
        
        var rating = try request.rating()
        rating.date_rated = stringDate
        rating.user_id = user?.id
        try rating.save()
        try apply_average_rating(rating: rating)
        return rating
    }
    
    func apply_average_rating(rating: Rating) throws {
        var place = try rating.place()
        if let place_id = place?.id?.int {
            if let service_average = average_rating(place_id: place_id).service, let food_average = average_rating(place_id: place_id).food {
                place?.service_average = service_average
                place?.food_average = food_average
            }
        }
        try place?.save()
    }
    
    func average_rating(place_id: Int) -> (service: Double?, food: Double?) {
        var all_ratings = [Rating]()
        do {
            all_ratings = try Rating.query().filter("place_id", .equals, place_id).all()
        } catch {
            print("Failed get all Ratings")
        }
        let service_number = all_ratings.map({ Double($0.service) })
        let service_average = service_number.reduce(0, +) / Double(service_number.count)
        let food_number = all_ratings.map({ Double($0.food) })
        let food_average = food_number.reduce(0, +) / Double(food_number.count)
        return (service: service_average, food: food_average)
    }
    
    func show(request: Request, rating: Rating) throws -> ResponseRepresentable {
        return try JSON(node: [rating, rating.user()?.username])
    }
    
    func update(request: Request, rating: Rating) throws -> ResponseRepresentable {
        let updated = try request.rating()
        var rating = rating
        rating.food = updated.food
        rating.service = updated.service
        try rating.save()
        return rating
    }
    
    func delete(request: Request, rating: Rating) throws -> ResponseRepresentable {
        try rating.delete()
        return JSON([:])
    }
    
    func makeResource() -> Resource<Rating> {
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
    func rating() throws -> Rating {
        guard let json = json else { throw Abort.badRequest }
        return try Rating(node: json)
    }
}
