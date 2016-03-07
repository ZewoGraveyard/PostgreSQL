//
//  Model.swift
//  PostgreSQL
//
//  Created by David Ask on 02/03/16.
//
//

@_exported import SQL

public protocol Model: SQL.Model {
    
}

public extension Model {
    public mutating func create<T: SQL.Connection where T.ResultType.Generator.Element == Row>(connection: T) throws {
        self = try Self.create(persistedValuesByField, connection: connection)
    }
    
    public static func create<T: SQL.Connection where T.ResultType.Generator.Element == Row>(values: [Field: SQLDataConvertible?], connection: T) throws -> Self {
        let insert: ModelInsert<Self> = ModelInsert(values)
        var components = insert.queryComponents
        components.append(QueryComponents(strings: ["RETURNING", Self.declaredPrimaryKeyField.qualifiedName, "AS", "returned__pk"]))
        
        let result = try connection.execute(components)
        
        guard let pk: PrimaryKeyType = try result.first?.value("returned__pk") else {
            throw ModelError(description: "Did not receive returned primary key")
        }
        
        guard let insertedObject = try Self.find(pk, connection: connection) else {
            throw ModelError(description: "Could not find model with primary key \(pk)")
        }
        
        return insertedObject
    }
}
