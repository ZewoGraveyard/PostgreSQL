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

extension User: Entity {
    enum Field: String , ModelFieldset{
        case Id = "id"
        case Username = "username"
        case Password = "password"
        case FirstName = "first_name"
        case LastName = "last_name"
        
        static let tableName: String = "users"
    }
    
    static let fieldForPrimaryKey: Field = .Id
    
    var primaryKey: Int? {
        return id
    }
    
    init(row: Row) throws {
        id = try row.value(Field.Id)
        username = try row.value(Field.Username)
        password = try row.value(Field.Password)
        firstName = try row.value(Field.FirstName)
        lastName = try row.value(Field.LastName)
    }
}
