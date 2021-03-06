import PackageDescription

let package = Package(
    name: "GrubAPI",
    dependencies: [
        .Package(url: "https://github.com/vapor/vapor.git", majorVersion: 1, minor: 3),
        .Package(url: "https://github.com/vapor/postgresql-provider", majorVersion: 1, minor: 0),
        .Package(url: "https://github.com/vapor/jwt.git", majorVersion: 0, minor: 6)
    ],
    exclude: [
        "Config",
        "Database",
        "Localization",
        "Public",
        "Resources",
        "Tests",
    ]
)

