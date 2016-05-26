//
//  Order.swift
//  PostgreSQL
//
//  Created by David Ask on 18/02/16.
//
//

import SQL

struct Album {
    struct Error: ErrorProtocol {
        let description: String
    }
    
    let id: Int?
    var name: String
    var artistId: Int
    
    var changedFields: [Field]? = []
    
    init(name: String, artist: Artist) throws {
        guard let artistId = artist.id else {
            throw Error(description: "Artist doesn't have an id yet")
        }
        
        self.name = name
        self.artistId = artistId
        self.id = nil
    }
}


extension Album: Model {
    enum Field: String {
        case id = "id"
        case name = "name"
        case artistId = "artist_id"
        case numberOfPlays = "play_number"
    }
    
    static let tableName: String = "albums"
    
    static let fieldForPrimaryKey: Field = .id

    var primaryKey: Int? {
        return id
    }
    
    init(row: Row) throws {
        id = try row.value(Album.field(.id))
        name = try row.value(Album.field(.name))
        artistId = try row.value(Album.field(.artistId))
    }
}

