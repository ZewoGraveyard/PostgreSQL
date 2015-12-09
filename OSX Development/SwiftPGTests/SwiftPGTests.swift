//
//  SwiftPGTests.swift
//  SwiftPGTests
//
//  Created by David Ask on 08/12/15.
//  Copyright © 2015 Formbound. All rights reserved.
//

import XCTest
import SwiftPG
import SwiftSQL


class SwiftPGTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        let connection = PGConnection(PGConnection.Info(host: "localhost", database: "swift_test"))
        
        do {
            try connection.open()
            
            let result = try connection.execute("SELECT * FROM films")
            
            print(result.fields)
            print(result.countAffected)
           
            
            for row in result {
                print(row["title"])
            }
        }
        catch {
            print(error)
        }
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
