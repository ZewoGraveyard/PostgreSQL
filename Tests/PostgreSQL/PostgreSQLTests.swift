//
//  PostgreSQLTests.swift
//  PostgreSQL
//
//  Created by David Ask on 17/02/16.
//
//

import XCTest
@testable import PostgreSQL


public final class StandardOutputAppender: Appender {
    public var name: String = "Standard Output Appender"
    public var closed: Bool = false
    public var level: Log.Level = .all
    
    public init () {}
    
    public func append(_ event: LoggingEvent) {
        var logMessage = "\(event.message) \n"
        let file = event.locationInfo.file
        logMessage += "In File: \(file)"
        logMessage += "\n"
        let line = event.locationInfo.line
        logMessage += "Line: \(line)"
        logMessage += "\n"
        let function = event.locationInfo.function
        logMessage += "Called From: \(function)"
        logMessage += "\n"
        print(logMessage)
    }
}

// MARK: - Models

struct Artist {
    var name: String
    var genre: String

    init(name: String, genre: String) {
        self.name = name
        self.genre = genre
    }
}

extension Artist: ModelProtocol {
    typealias PrimaryKey = Int
    
    enum Field: String {
        case id = "id"
        case name = "name"
        case genre = "genre"
    }
    
    static let tableName: String = "artists"
   	static var primaryKeyField: Field = .id
   
    
    func serialize() -> [Field: ValueConvertible?] {
        return [.name: name, .genre: genre]
    }
    
    init<T: RowProtocol>(row: T) throws {
        try self.init(
            name: row.value(Artist.field(.name)),
            genre: row.value(Artist.field(.genre))
        )
    }
}

final class Album {
    var name: String
    var artistId: Artist.PrimaryKey
    
    init(name: String, artistId: Artist.PrimaryKey) {
        self.name = name
        self.artistId = artistId
    }
}

extension Album: ModelProtocol {
    typealias PrimaryKey = Int
    
    enum Field: String {
        case id = "id"
        case name = "name"
        case artistId = "artist_id"
    }
    
    static let tableName: String = "artists"
   	static let primaryKeyField: Field = .id
    
    func serialize() -> [Field: ValueConvertible?] {
        return [ .name: name, .artistId: artistId ]
    }
    
    convenience init<T: RowProtocol>(row: T) throws {
        try self.init(
            name: row.value(Album.field(.name)),
            artistId: row.value(Album.field(.artistId))
        )
        
    }    
}

// MARK: - Tests

public class PostgreSQLTests: XCTestCase {
    
    let connection = try! PostgreSQL.Connection(URI("postgres://localhost:5432/swift_test"))
    

    let logger = Logger(name: "SQL Logger", appenders: [StandardOutputAppender()])

    
    override func setUp() {
        super.setUp()
        
        do {
            try connection.open()
            try connection.execute("DROP TABLE IF EXISTS albums")
            try connection.execute("DROP TABLE IF EXISTS artists")
            try connection.execute("CREATE TABLE IF NOT EXISTS artists(id SERIAL PRIMARY KEY, genre VARCHAR(50), name VARCHAR(255))")
            try connection.execute("CREATE TABLE IF NOT EXISTS albums(id SERIAL PRIMARY KEY, name VARCHAR(255), artist_id int references artists(id))")
            
            try connection.execute("INSERT INTO artists (name, genre) VALUES('Josh Rouse', 'Country')")
            
            connection.logger = logger
            
            
        }
        catch {
            XCTFail("Connection error: \(error)")
        }
    }
    
    func testSimpleRawQueries() throws {
        try connection.execute("SELECT * FROM artists")
        let result = try connection.execute("SELECT * FROM artists WHERE name = %@", parameters: "Josh Rouse")

        XCTAssert(try result.first?.value("name") == "Josh Rouse")
    }
    
    func testBulk() {
        do {
            for i in 0..<300 {
                var entity = Entity(model: Artist(name: "NAME \(i)", genre: "GENRE \(i)"))
                try entity.save(connection: connection)
            }
            
            measure {
                do {
                    let result = try Entity<Artist>.fetchAll(connection: self.connection)
                    
                    for artist in result {
                        print(artist.model.genre)
                    }
                }
                catch {
                    XCTFail("\(error)")
                }
            }
        }
        catch {
            print("ERROR")
            XCTFail("\(error)")
        }
    }
    
    func testRockArtists() throws {
        

        do {
            let artists = try Entity<Artist>.fetchAll(connection: connection)
            
            try Entity<Artist>.fetchAll(connection: connection)
            
            try connection.begin()
            
            for var artist in artists {
                artist.model.genre = "Rock & Roll"
                try artist.save(connection: connection)
            }
            
            try connection.commit()
        }
        catch {
            print(error)
            throw error
        }
        
        
    }
    
    
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        
        connection.close()
        
    }
}
