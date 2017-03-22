import Vapor
import VaporPostgreSQL
import Auth

let drop = Droplet()
try drop.addProvider(VaporPostgreSQL.Provider.self)
drop.preparations = [Place.self, Rating.self, User.self]
drop.middleware.insert(CORSMiddleware(), at: 0)

let loginController = LoginController()
loginController.addRoutes(drop: drop)

let grubController = GrubController()
grubController.addRoutes(drop: drop)

let placeController = PlaceController()
drop.grouped("v1").grouped(TokenAuthMiddleware()).resource("places", placeController)

let ratingController = RatingController()
drop.grouped("v1").grouped(TokenAuthMiddleware()).resource("ratings", ratingController)

drop.run()
