import PackageDescription

let package = Package(
	name: "PostgreSQLExample",
	dependencies: [
		.Package(url: "https://github.com/Zewo/PostgreSQL", majorVersion: 0)
	]
)
