//
//  PostgreSQLTests.swift
//  PostgreSQLTests
//
//  Created by David Ask on 23/12/15.
//  Copyright © 2015 Zewo. All rights reserved.
//

import XCTest
import SQL
import PostgreSQL



class PostgreSQLTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        let connection = Connection("postgres://localhost/swift_test")
        
        do {
            try connection.open()
            try connection.execute("CREATE TABLE IF NOT EXISTS points (id SERIAL PRIMARY KEY, name VARCHAR(256), serial VARCHAR(256) UNIQUE, location POINT)")
            
            let result = try connection.execute("SELECT * FROM points")
            
            for row in result {
                print(row["location"]?.point)
                print(row["location"])
                print("!")
            }
        }
        catch {
            print(error)
            print("!")
        }
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
