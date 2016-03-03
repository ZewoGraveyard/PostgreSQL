//
//  BaseModel.swift
//  PostgreSQL
//
//  Created by David Ask on 18/02/16.
//
//

import PostgreSQL

struct User {
    var id: Int?
    var username: String
    var password: String
    var firstName: String?
    var lastName: String?
    
    var dirtyFields: [Field] = []
    
    init(username: String, password: String, firstName: String?, lastName: String?) {
        self.username = username
        self.password = password
        self.firstName = firstName
        self.lastName = lastName
    }
}

extension User: Model {
    enum Field: String, FieldType {
        case Id = "id"
        case Username = "username"
        case Password = "password"
        case FirstName = "first_name"
        case LastName = "last_name"
    }
    
    static let tableName: String = "users"
    
    static let fieldForPrimaryKey: Field = .Id
    
    static let selectFields: [Field] = [
        .Id,
        .Username,
        .Password,
        .FirstName,
        .LastName
    ]
    
    var primaryKey: Int? {
        return id
    }
    
    
    init(row: Row) throws {
        id = try row.value(User.field(.Id))
        username = try row.value(User.field(.Username))
        password = try row.value(User.field(.Password))
        firstName = try row.value(User.field(.FirstName))
        lastName = try row.value(User.field(.LastName))
    }
    
    var persistedValuesByField: [Field: SQLDataConvertible?] {
        return [
            .Username: username,
            .Password: password,
            .FirstName: firstName,
            .LastName: lastName
        ]
    }
}