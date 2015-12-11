//
//  Field.swift
//  Postgres
//
//  Created by David Ask on 09/12/15.
//  Copyright © 2015 Formbound. All rights reserved.
//

import SQL

public struct Field: SQL.Field {
    public var name: String
    
    init(name: String) {
        self.name = name
    }
}
