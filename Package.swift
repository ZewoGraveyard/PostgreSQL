import PackageDescription

let package = Package(
    name: "Postgres",
    dependencies: [
        .Package(url: "https://github.com/formbound/SwiftSQL.git", majorVersion: 0, minor: 1),
	.Package(url: "https://github.com/formbound/libpq.git", majorVersion: 9)
    ]
)
