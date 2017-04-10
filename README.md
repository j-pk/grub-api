**GrubAPI**
----
Grub API was created to help with meal time decisions. 
  
API URL: https://grubapi.heroku.com/v1

### Register & Login

Send a post request with a json that has a `username` and `password` to register a new user. `username` needs to be more than 3 characters long and `passwords` should be at least 6.   

```
{
	"username": "ricky_bobby",
	"password": "gofast"
}
```

Send a similar JSON to login in as well. Below is an example response.

```
{
  "status": "ok",
  "user": {
    "id": 2,
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHBpcmVzIjo1MDgzODkwNjAuNTk3NTIzLCJ1c2VybmFtZSI6ImZpdmUifQ==.pGQl3jFf8PA+3yynhPXOxYGtuoLWASUJWvDMiH82e30=",
    "username": "ricky_bobby"
  }
}
```

When making a request be sure to put `Authorization: Bearer access_token` in your header or your request will fail. Access tokens expire in `x` hours, be sure to reauthenticate when necessary. Passwords are hashed. Request errors should be self explanatory. 

### Place		

The `place` object contain useful information about an eating place like location, menus, and ratings.

|     Attribue    |    Type   |                                            Description                                           |      Optional?     |
|:---------------:|:---------:|:------------------------------------------------------------------------------------------------:|:------------------:|
|       name      |   string  |                                        name of meal place                                        |      required      |
|     location    |   string  |                                      location of meal place                                      |      required      |
|   website_url   |   string  |                                  website address for meal place                                  |      optional      |
|     menu_url    |   string  |                                    menu address for meal place                                   |      optional      |
|       cost      |    int    |                        0 - Cheap, 1 - Tolerable, 2 - Pricey, 3 - Expensive                       |      optional      |
|      genre      | enum(int) |          0 - Asian,  1 - Mexican, 2 - Italian, 3 - Indian, 4 - American,  5 - French             |      optional      |
|   service_type  | enum(int) | 0 - Fast-Food,  1 - Traditional,  2 - Fine Dining,  3 - Bar,  4 - Bistro,  5 - Cafe, 6 - Counter |      optional      |
|        id       |    int    |                                  database identification number                                  |      read-only     |
| service_average |  double?  |                                    average rating for service                                    | optional read-only |
|   food_average  |  double?  |                                      average rating for food                                     | optional read-only |

**JSON example:**

```
  {
    "cost": 0,
    "food_average": 2.5,
    "genre": 4,
    "id": 1,
    "location": "1197 Peachtree St Ne , Atlanta , GA 30309",
    "menu_url": "https://www.chick-fil-a.com/#entrees",
    "name": "Chick-fil-A",
    "service_average": 2.5,
    "service_type": 0,
    "website_url": "https://www.chick-fil-a.com/Locations/GA/Colony-Square"
  }
```

**Endpoints**

|        Usage       |    Endpoint       | Method |      Returns      |
|:------------------:|:-----------------:|:------:|:-----------------:|
|   Get all places   |     /places       |   GET  |      [Place]      |
|   Get all genres   | /places/genre/:id |   GET  |      [Place]      |
|     Get a place    |   /places/:id     |   GET  |       Place       |
| Get a random place | /places/random    |   GET  |       Place       |
|     Add a place    |     /places       |  POST  |       Place       |
|   Update a place   |   /places/:id     |  PATCH |       Place       |
|   Delete a place   |   /places/:id     |  POST  | 200 HTTP Response |


***
### Rating    

The `rating` object contains information about the quality of a place's food and service.

|  Attribue  |    Type   |                        Description                        | Optional? |
|:----------:|:---------:|:---------------------------------------------------------:|:---------:|
|  place_id  |    int    |         meal place database identification number         |  required |
|    food    | enum(int) | 0 - terrible, 1 - bad, 2 - tolerable, 3 - good, 4 - great |  required |
|   service  | enum(int) | 0 - terrible, 1 - bad, 2 - tolerable, 3 - good, 4 - great |  required |
|   user_id  |    int    |             user database identification number           | read-only |
|  username  |   string  |                        username                           |  required |
|   comment  |   string  |                  space to leave a review                  |  optional |
| date_rated |   string  |               time when the place was rated               | read-only |


**JSON example:** 

```
{
	"comment": "Pretty good sushi. ",
	"date_rated": "2017-03-12T15:33:46Z",
	"food": 1,
	"id": 5,
	"place_id": 2,
	"service": 3,
	"user_id": 2,
	"username": "five2"
}
```

**Endpoints**

|            Usage            |   Endpoint   | Method |      Returns      |
|:---------------------------:|:------------:|:------:|:-----------------:|
|       Get all ratings       |   /ratings   |   GET  |      [Rating]     |
| Get all ratings for a place |  /places/:id |   GET  | [Place: [Rating]] |
|         Get a rating        | /ratings/:id |   GET  |       Rating      |
|         Add a rating        |   /ratings   |  POST  |       Rating      |
|       Update a rating       | /ratings/:id |   PUT  |       Rating      |
|       Delete a rating       | /ratings/:id |  POST  | 200 HTTP Response |

---

### Search

|                 Usage                 |    Endpoint    | Method |  Return |
|:-------------------------------------:|:--------------:|:------:|:-------:|
| Get all places containing search name | /places/search |  POST  | [Place] |

Example `POST` request  

```
{
  "name": "Chick"
}
```

**Location**  
Find places based on location. 

| Attribute |  Type  |         Description        | Optional? |
|:---------:|:------:|:--------------------------:|:---------:|
|    name   | string | name or keyword for search |  required |
|  latitude | double |    latitude of location    |  required |
| longitude | double |    longitude of location   |  required |
|   radius  |   int  |  parameter for search area |  required |

**Endpoints**


|            Usage            | Endpoint                 | Method |        Returns       |
|:---------------------------:|:------------------------:|:------:|:--------------------:|
| Get all places by lat, long |  /places/location/search |  POST  |       [Places]       |

Example `POST` request  
*Note*: radius is measured in meters with an allowed **maxium** of 50,000 meters.    

```
{
  "name": "Zaxby's",
  "latitude": 33.894438,
  "longitude": -84.468557,
  "radius": 3300
}
```

### Version

|              Usage             | Endpoint | Method |                   Returns                  |
|:------------------------------:|:--------:|:------:|:------------------------------------------:|
| Get API and DB version numbers | /version |   GET  | { grubapi version, postgresql db version } |


---
### Tasks 

* [x] OAuth, Salt and Hash Password
* [x] Add User relationship to Place
* [ ] Add attributes to place; happy hour times, specials and distance from office (walkability)
* [ ] iOS, Android, ~~Web~~ presence 
* [ ] I don't know.. any suggestions? 


***Notes:*** 
This API is using [Vapor](https://github.com/vapor/vapor), a web and server framework written in Swift. Database made with [PostgreSQL](https://www.postgresql.org/about/). Location services powered by [Google Place API](https://developers.google.com/places/)

