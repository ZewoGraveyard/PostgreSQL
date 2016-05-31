//
//  Row.swift
//  PostgreSQL
//
//  Created by David Ask on 31/05/16.
//
//

import CLibpq
@_exported import SQL

public struct Row: RowProtocol {
    public let result: Result
    
    public let index: Int
    
    public init(result: Result, index: Int) {
        self.result = result
        self.index = index
    }
}

