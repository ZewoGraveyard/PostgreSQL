//
//  PostgreSQLTests.swift
//  PostgreSQL
//
//  Created by David Ask on 17/02/16.
//
//

import XCTest
@testable import PostgreSQL


class PostgreSQLTests: XCTestCase {
    
    let connection = PostgreSQL.Connection("postgres://localhost/swift_test")
    let log = Log()
    
    override func setUp() {
        super.setUp()
        connection.log = log
        
        do {
            try connection.open()
        }
        catch {
            XCTFail("Connection error: \(error)")
        }
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        
        connection.close()
    }
    
    func testSimpleQuery() {
        do {
            try self.connection.execute("SELECT * FROM users WHERE id = \(1) OR id = \(2)")
        }
        catch {
            XCTFail("\(error)")
        }
    }
    
    func testDSL() {
        do {
            
            if var user = try User.find(1, connection: connection) {
                print(user)
                
                
                user.lastName = "Askyyy"

                try user.update(connection)
                print(user)
                
            }
            
            
        
            print("!")
            
        }
        catch {
            XCTFail("\(error)")
        }
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            do {
                //                try User.select().filter(User.field(.Id) == 1 || User.Field.Username == "David" || User.Field.Password == "123456").fetch(self.connection)
            }
            catch {
                XCTFail("\(error)")
            }
        }
    }
    
}


