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
            
            
            
            let firstQuery =
                Album.select(.id, .name, .artistId)
                .extend(
                    sum(Album.field(.numberOfPlays), as: "numPlays"),
                    Select("*", from: "genres").subquery(as: "genres")
                    )
                .join(.inner(Artist.tableName), on: Album.field(.artistId), equals: Artist.field(.id))
                .filter(Artist.field(.name).containedIn("Josh Rouse", "AC/DC"))
                .offset(10)
                .first
            
            
            
            
            try connection.execute(firstQuery)
            
            
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


