import PackageDescription
import Foundation

#if os(OSX)
	let libpqURL = "https://github.com/formbound/CLibpq-OSX.git"
#else
	let libpqURL = "https://github.com/Zewo/CLibpq.git"
#endif

let package = Package(
    name: "PostgreSQL",
    dependencies: [
        .Package(url: "https://github.com/Zewo/SQL.git", majorVersion: 0),
		.Package(url: libpqURL, majorVersion: 0)
    ]
)
