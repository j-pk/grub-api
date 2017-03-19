import Vapor

final class Place: Model {
    var id: Node?
    var exists: Bool = false

    var name: String
    var location: String
    var website_url: String?
    var menu_url: String?
    var service_type: Int?
    var cost: Int?
    var genre: Int?
    var service_average: Double?
    var food_average: Double?
    
    init(name: String, location: String, website_url: String? = nil, menu_url: String? = nil, service_type: Int? = nil, cost: Int? = nil, genre: Int? = nil, service_average: Double? = nil, food_average: Double? = nil) {
        self.id = nil
        self.service_average = nil
        self.food_average = nil
        self.name = name
        self.location = location
        self.website_url = website_url
        self.menu_url = menu_url
        self.service_type = service_type
        self.cost = cost
        self.genre = genre
    }
    
    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        name = try node.extract("name")
        location = try node.extract("location")
        website_url = try node.extract("website_url")
        menu_url = try node.extract("menu_url")
        service_type = try node.extract("service_type")
        cost = try node.extract("cost")
        genre = try node.extract("genre")
        service_average = try node.extract("service_average")
        food_average = try node.extract("food_average")
    }
    
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: ["id": id,
                               "name": name,
                               "location": location,
                               "website_url": website_url,
                               "menu_url": menu_url,
                               "service_type": service_type,
                               "cost": cost,
                               "genre": genre,
                               "service_average": service_average,
                               "food_average": food_average])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create("places", closure: { places in
            places.id()
            places.string("name")
            places.string("location")
            places.string("website_url", optional: true)
            places.string("menu_url", optional: true)
            places.int("service_type", optional: true)
            places.int("cost", optional: true)
            places.int("genre", optional: true)
            places.double("service_average", optional: true)
            places.double("food_average", optional: true)
        })
    }
    
    static func revert(_ database: Database) throws {
        try database.delete("places")
    }
}

extension Place {
    func ratings() throws -> [Rating] {
        return try children(nil, Rating.self).all()
    }
}
