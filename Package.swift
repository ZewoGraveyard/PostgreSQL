import PackageDescription
import Foundation

#if os(Linux)
    let libpqURL = "https://github.com/Zewo/CLibpq.git"
#else
    let libpqURL = "https://github.com/formbound/CLibpq-OSX.git"
#endif

let package = Package(
    name: "PostgreSQL",
    dependencies: [
        .Package(url: "https://github.com/Zewo/SQL.git", majorVersion: 0),
		.Package(url: libpqURL, majorVersion: 0)
    ]
)
