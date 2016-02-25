//
//  BaseModel.swift
//  PostgreSQL
//
//  Created by David Ask on 18/02/16.
//
//

import SQL

struct User {
    var id: Int?
    var username: String
    var password: String
    var firstName: String?
    var lastName: String?
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
    
    var persistedValuesByField: [Field: ValueConvertible?] {
        return [
            .Username: username,
            .Password: password,
            .FirstName: firstName,
            .LastName: lastName
        ]
    }
}