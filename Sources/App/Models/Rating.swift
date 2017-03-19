import Vapor

final class Rating: Model {
    var place_id: Node?
    var user_id: Node?
    var id: Node?
    var exists: Bool = false
    
    var service: Int
    var food: Int
    var date_rated: String?
    var comment: String?
    var username: String
    
    init(service: Int, food: Int, place_id: Node? = nil, username: String, user_id: Node? = nil, date_rated: String? = nil, comment: String? = nil) {
        self.service = service
        self.food = food
        self.place_id = place_id
        self.user_id = user_id
        self.username = username
        self.date_rated = date_rated
        self.comment = comment
    }
    
    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        place_id = try node.extract("place_id")
        user_id = try node.extract("user_id")
        username = try node.extract("username")
        food = try node.extract("food")
        service = try node.extract("service")
        date_rated = try node.extract("date_rated")
        comment = try node.extract("comment")
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: ["id": id,
                               "food": food,
                               "service": service,
                               "place_id": place_id,
                               "user_id": user_id,
                               "username": username,
                               "date_rated": date_rated,
                               "comment": comment
                               ])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create("ratings", closure: { ratings in
            ratings.id()
            ratings.double("service")
            ratings.double("food")
            ratings.string("date_rated")
            ratings.string("comment")
            ratings.string("username")
            ratings.parent(Place.self, optional: false)
            ratings.parent(User.self, optional: false)
        })
    }
    
    static func revert(_ database: Database) throws {
        try database.delete("ratings")
    }
}

extension Rating {
    func place() throws -> Place? {
        return try parent(place_id, nil, Place.self).get()
    }
    func user() throws -> User? {
        return try parent(user_id, nil, User.self).get()
    }
}
