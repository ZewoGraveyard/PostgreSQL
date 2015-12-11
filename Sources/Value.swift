//
//  Value.swift
//  Postgres
//
//  Created by David Ask on 10/12/15.
//  Copyright © 2015 Formbound. All rights reserved.
//

import SQL

public struct Value: SQL.Value  {
    
    public let data: [UInt8]
    
    public init(data: [UInt8]) {
        self.data = data
    }
}