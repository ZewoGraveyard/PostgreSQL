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
            
            try conn.execute("CREATE TABLE IF NOT EXISTS todos (id SERIAL PRIMARY KEY, name varchar(50))")
            
//            try conn.begin()
//            
//            for i in 0..<100 {
//                try conn.execute("INSERT INTO todos (name) VALUES('Todo \(i)')")
//            }
//        
//            
//            try conn.commit()
            
            let count = try conn.execute("SELECT COUNT(*) FROM films")
            var generator = count.generate()
            
            print("COUNT: \(count.count)")
            print("FIRST: \(count.first)")
            print("LAST: \(count.last)")
            
            while let obj = generator.next() {
                print(obj)
            }
        
            let result = try conn.execute("SELECT * FROM films")
            
            //try connection.createSavePointNamed("my_savepoint")
            
            print(result.fields)
            print(result.countAffected)
            
            
            for row in result {
                print(row["id"]?.integer)
            }
            
            //try connection.rollbackToSavePointNamed("my_savepoint")
            
            //try connection.releaseSavePointNamed("my_savepoint")
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
