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
    
}

extension Order: Entity {
    enum Field: String , ModelFieldset{
        case Id = "id"
        case UserId = "user_id"
        case Timestamp = "timestamp"
        
        static let tableName: String = "orders"
    }
    
    static let fieldForPrimaryKey: Field = .Id
    
    var primaryKey: Int? {
        return id
    }
    
    init(row: Row) throws {
        id = try row.value(Field.Id)
        userId = try row.value(Field.UserId)
        timestamp = try row.value(Field.Timestamp)
    }
}

