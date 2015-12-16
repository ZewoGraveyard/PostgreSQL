//
//  PostgresTests.swift
//  PostgresTests
//
//  Created by David Ask on 09/12/15.
//  Copyright © 2015 Formbound. All rights reserved.
//

import XCTest
import Postgres
import SQL

class PostgresTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        let conn = Connection("postgres://localhost/swift_test")
        
        do {
            
            try conn.open()
            

            let result = try conn.execute(
                "SELECT * FROM films where title = :title",
                parameters:  [
                    "title": "Shawshank Redemption"
                ]
            )

            
            for row in result {
                print("Title: \(row["title"]?.string)")
            }
        }
        catch {
            print(error)
        }
        
        conn.close()
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
}
