Postgres
========

[![Swift 2.2](https://img.shields.io/badge/Swift-2.2-orange.svg?style=flat)](https://swift.org)
[![Platforms Linux](https://img.shields.io/badge/Platforms-Linux-lightgray.svg?style=flat)](https://swift.org/download/#linux)
[![License MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=flat)](https://tldrlegal.com/license/mit-license)
[![Slack Status](http://slack.zewo.io/badge.svg)](http://slack.zewo.io)

**PostgreSQL** adapter for **Swift 2.2**.

## Usage

```swift
let conn = Connection("postgres://localhost/swift_test")
do {
	try conn.open()
	try conn.execute("INSERT INTO films (name) VALUES('Shawshank redemption')")
	let result = try conn.execute("SELECT * FROM films")
	for row in result {
        print(row["id"]?.integer)
    }
}
catch {
	print(error)
}
```

## Installation

- Install libpq-dev

```bash
$ (sudo) apt-get install libpq-dev
```

- Add `Postgres` to your `Package.swift`

```swift
import PackageDescription

let package = Package(
	dependencies: [
		.Package(url: "https://github.com/Zewo/Postgres.git", majorVersion: 0)
	]
)

```

## Community

[![Slack](http://s13.postimg.org/ybwy92ktf/Slack.png)](http://slack.zewo.io)

Join us on [Slack](http://slack.zewo.io).

License
-------

**Postgres** is released under the MIT license. See LICENSE for details.