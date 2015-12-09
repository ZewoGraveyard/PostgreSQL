import PackageDescription

let package = Package(
    name: "SwiftFoundation",
    dependencies: [
        .Package(url: "://github.com/formbound/SwiftSQL.git", majorVersion: 1),
	.Package(url: "://github.com/formbound/libpq.git", majorVersion: 1)
    ]
)
