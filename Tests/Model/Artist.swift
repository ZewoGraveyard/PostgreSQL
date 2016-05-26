//
//  BaseModel.swift
//  PostgreSQL
//
//  Created by David Ask on 18/02/16.
//
//

import SQL

struct Artist {
    let id: Int?
    var name: String
    var genre: String?
    
    var changedFields: [Field]? = []
    
    init(name: String, genre: String) {
        self.id = nil
        self.name = name
        self.genre = genre
    }
}

extension Artist: Model {
    enum Field: String {
        case id = "id"
        case name = "name"
        case genre = "genre"
    }
    
    static let tableName: String = "artists"
   	static let fieldForPrimaryKey: Field = .id

    
    var primaryKey: Int? {
        return id
    }

    init(row: Row) throws {
        id = try row.value(Artist.field(.id))
        name = try row.value(Artist.field(.name))
        genre = try row.value(Artist.field(.genre))
    }
    
    func willSave() {
        print("Will save")
    }
}