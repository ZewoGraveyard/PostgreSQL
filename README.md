PostgreSQL
==========

[![Swift 2.2](https://img.shields.io/badge/Swift-2.2-orange.svg?style=flat)](https://swift.org)
[![Platforms Linux](https://img.shields.io/badge/Platforms-Linux-lightgray.svg?style=flat)](https://swift.org/download/#linux)
[![License MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=flat)](https://tldrlegal.com/license/mit-license)
[![Slack Status](http://slack.zewo.io/badge.svg)](http://slack.zewo.io)

**PostgreSQL** adapter for **Swift 2.2**.

## Installation

- Install libpq-dev

### Linux

```bash
$ (sudo) apt-get install libpq-dev
```

### OSX

```bash
$ brew install postgresql
```

- Add `PostgreSQL` to your `Package.swift`

```swift
import PackageDescription

let package = Package(
	dependencies: [
		.Package(url: "https://github.com/Zewo/PostgreSQL.git", majorVersion: 0, minor: 3)
	]
)

```

## Community

[![Slack](http://s13.postimg.org/ybwy92ktf/Slack.png)](http://slack.zewo.io)

Join us on [Slack](http://slack.zewo.io).

License
-------

**PostgreSQL** is released under the MIT license. See LICENSE for details.
