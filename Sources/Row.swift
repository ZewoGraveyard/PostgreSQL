//
//  Row.swift
//  Postgres
//
//  Created by David Ask on 10/12/15.
//  Copyright © 2015 Formbound. All rights reserved.
//

import SQL

public struct Row: SQL.Row {
    public let valuesByName: [String: Value]
    
    public init(valuesByName: [String: Value]) {
        self.valuesByName = valuesByName
    }
}
