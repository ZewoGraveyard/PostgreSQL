//
//  Order.swift
//  PostgreSQL
//
//  Created by David Ask on 18/02/16.
//
//

import SQL

struct Order {
    var id: Int?
    var userId: Int?
    var timestamp: String
    
    var changes: [Field : ValueConvertible?] = [:]
}

extension Order: Model {
    enum Field: String, FieldType{
        case Id = "id"
        case UserId = "user_id"
        case Timestamp = "timestamp"
    }
    
    static let tableName: String = "orders"
    
    static let fieldForPrimaryKey: Field = .Id
    
    var primaryKey: Int? {
        return id
    }
    
    init(row: Row) throws {
        id = try row.value(Order.field(.Id))
        userId = try row.value(Order.field(.UserId))
        timestamp = try row.value(Order.field(.Timestamp))
    }
    
    var persistedValuesByField: [Field: ValueConvertible?] {
        return [
            .UserId: userId,
            .Timestamp: timestamp
        ]
    }
}

