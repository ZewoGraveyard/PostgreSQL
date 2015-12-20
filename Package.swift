import PackageDescription

#if os(OSX)
	let libpqURL = "https://github.com/formbound/CLibpq-OSX.git"
#else
	let libpqURL = "https://github.com/Zewo/CLibpq.git"
#endif

let package = Package(
    name: "PostgreSQL",
    dependencies: [
        .Package(url: "https://github.com/Zewo/SQL.git", majorVersion: 0, minor: 1),
		.Package(url: libpqURL, majorVersion: 0, minor: 1),
		.Package(url: "https://github.com/Zewo/CURIParser.git", majorVersion: 0, minor: 1)
    ]
)
