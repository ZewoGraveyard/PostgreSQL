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

class PostgreSQLTests: XCTestCase {
    
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
            
            connection.logger = logger
            
        }
        catch {
            XCTFail("Connection error: \(error)")
        }
    }
    
    func testGenerator() {
        do {
            try Insert(["name": "Lady Gaga"], into: "artists").execute(connection)
            try Insert(["name": "Mike Snow"], into: "artists").execute(connection)
            
            for row in try connection.execute("SELECT * FROM artists") {
                let name: String? = try row.value("name")
                let data = try row.data("name")
                
                print(name)
                print(data)
            }
        }
        catch {
            XCTFail("\(error)")
        }
    }
    
    func testSimpleQueries() {
        do {
            try connection.execute("SELECT * FROM artists")
            try connection.execute("SELECT * FROM artists WHERE name = %@", parameters: "Josh Rouse")
        }
        catch {
            XCTFail("\(error)")
        }
    }
    
    func testSimpleDSLQueries() {
        do {
            try Select(["id", "name"], from: "artists").execute(connection)
            try Select(from: "artists").execute(connection)
            try Select(from: "artists").join("albums", using: .Inner, leftKey: "artists.id", rightKey: "albums.artist_id").execute(connection)
            try Select(from: "artists").limit(10).offset(1).execute(connection)
            try Select(from: "artists").orderBy(.Descending("name"), .Ascending("id")).execute(connection)
            
            try Insert([Artist.field(.Name): "Lady Gaga"], into: Artist.tableName).execute(connection)
            
            try Update(Artist.tableName, set: [Artist.field(.Name): "Mike Snow"]).execute(connection)
            
            try Delete(from: "albums").execute(connection)
            
            try Select(from: "artists").filter(field("genre") == "rock" && field("name").like("%rock") || field("name") == "AC/DC").execute(connection)
            
            try Update("artists", set: ["genre": "rock"]).filter(field("name") == "AC/DC").execute(connection)
            
            try Delete(from: "artists").filter(field("name") == "Skrillex").execute(connection)
        }
        catch {
            XCTFail("\(error)")
        }
    }
    
    
    func testModelDSLQueries() {
        
        do {
            try Artist.selectQuery.fetch(connection)
            try Artist.get(1, connection: connection)
            
            try Artist.selectQuery.limit(10).offset(1).execute(connection)
            try Artist.selectQuery.orderBy(.Descending(.Name), .Ascending(.Id)).execute(connection)
            
            Artist.selectQuery.filter(Artist.field(.Id) == 1 || Artist.field(.Genre) == "rock")
            
            var newArtist = Artist(name: "AC/DC", genre: "Rock")
            try newArtist.create(connection)
            print(newArtist)
            
            var otherNewArtist = Artist(name: "Mötley Crue", genre: "glam rock")
            try otherNewArtist.create(connection)
            
            print(otherNewArtist)
            
            Select([Artist.field(.Id)], from: Artist.tableName)
            
            var artist = try Artist.selectQuery.first(connection) ?? Artist(name: "Anonymous", genre: "alternative")
            artist.genre = "UDPATED2"
            try artist.setNeedsSave(field: .Genre)
            try artist.save(connection)
            print(artist)
            
            try artist.delete(connection)
        }
        catch {
            XCTFail("\(error)")
        }
        
    }
    
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        
        connection.close()
        
    }
}


