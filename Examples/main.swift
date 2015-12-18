import PostgreSQL



let connection = Connection("postgres://localhost/swift_test")

do {
	try connection.open()

	try connection.execute(
		"DROP TABLE IF EXISTS todos"
	)

	try connection.execute(
		"CREATE TABLE todos (id SERIAL PRIMARY KEY, title VARCHAR(100) NOT NULL)"
	)

	let createTodos:[String] = [
		"Buy milk",
		"Call mom",
		"Write an awesome API"
	]

	for todoTitle in createTodos {
		try connection.execute("INSERT INTO TODOS (title) VALUES($1)", parameters: todoTitle)
	}

	let result = try connection.execute("SELECT * FROM todos")

	for row in result {
		print(row)
	}

}
catch {
	print(error)
}