import PackageDescription

#if os(OSX)
	let CLibpqURL = "https://github.com/Zewo/CLibpq-OSX.git"
#else
	let CLibpqURL = "https://github.com/Zewo/CLibpq.git"
#endif

let package = Package(
	name: "PostgreSQL",
	dependencies: [
		.Package(url: CLibpqURL, majorVersion: 0, minor: 4),
		.Package(url: "https://github.com/Zewo/SQL.git", majorVersion: 0, minor: 5),
	]
)
