import PackageDescription

#if os(OSX)
	let libpqURL = "https://github.com/Zewo/CLibpq-OSX.git"
#else
	let libpqURL = "https://github.com/Zewo/CLibpq.git"
#endif

let package = Package(
	name: "PostgreSQL",
	dependencies: [
		.Package(url: libpqURL, majorVersion: 0, minor: 2),
		.Package(url: "https://github.com/Zewo/SQL.git", majorVersion: 0, minor: 3),
		.Package(url: "https://github.com/Zewo/CLibvenice.git", majorVersion: 0, minor: 2)
	]
)
