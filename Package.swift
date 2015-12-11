import PackageDescription

let package = Package(
    name: "Postgres",
    dependencies: [
        .Package(url: "https://github.com/formbound/SQL.git", majorVersion: 0),
	.Package(url: "https://github.com/formbound/libpq.git", majorVersion: 9)
    ]
)
