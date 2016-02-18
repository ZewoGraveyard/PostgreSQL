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

    func testSimpleQuery() throws {
//        for i in 0...100 {
//           try self.connection.execute(Statement("SELECT * FROM users WHERE id = $1", parameters: [i]))
//        }
    }
    
    func testDSL() throws {
        let result = try User.select().join(.Inner(Order.self), on: .Id == .UserId).filter(User.Field.Id > 0).fetch(connection)
        print(result.count)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
           
        }
    }

}
