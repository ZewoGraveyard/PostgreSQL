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
    
    let connection = Connection("postgres://localhost/swift_test")
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
    
    func testQueryComponents() {
        let queryComponents: QueryComponents = "SELECT * FROM users WHERE id = \(1) OR id = \(2)"
        
        XCTAssert(queryComponents.values.count == 2)
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
            let result = try Select(from: "users", fields: "users.id", "users.username")
                .filter("users.id" == 1)
                .join("orders", using: .Inner, leftKey: "users.id", rightKey: "orders.user_id")
                .limit(1)
                .offset(1)
                .execute(connection)
            
            print(result)
        }
        catch {
            XCTFail("\(error)")
        }
    }
    
    func testModelDSL() {
        do {
            try User.select
                .filter(User.field(.Id) == 1)
                .join(Order.self, type: .Inner, leftKey: .Id, rightKey: .UserId)
                .order(.Ascending(.Id), .Descending(.FirstName))
                .limit(10)
                .offset(1)
                .fetch(connection)
            
            
        }
        catch {
            XCTFail("\(error)")
        }
    }
    
    func testModelInsert() {
        do {
            var user = User(
                username: "TestUser",
                password: "123145",
                firstName: "Test",
                lastName: "User"
            )
            
            try user.save(connection)
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


