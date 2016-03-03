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
    public mutating func insert<T: SQL.Connection where T.ResultType.Generator.Element == Row>(connection: T) throws {
        var components = Self.insert(set: persistedValuesByField).queryComponents
        components.append(QueryComponents(strings: ["RETURNING", Self.declaredPrimaryKeyField.qualifiedName, "AS", "returned__pk"]))
        
        let result = try connection.execute(components)
        
        guard let id: PrimaryKeyType = try result.first?.value("returned__pk") else {
            fatalError()
        }
        
        guard let newSelf = try Self.find(id, connection: connection) else {
            fatalError()
        }
        
        self = newSelf
    }
}
