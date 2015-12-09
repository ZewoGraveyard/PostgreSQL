//
//  PGField.swift
//  SwiftPG
//
//  Created by David Ask on 09/12/15.
//  Copyright © 2015 Formbound. All rights reserved.
//

import SwiftSQL

public struct PGField : Field {
    public var name: String
    
    init(name: String) {
        self.name = name
    }
}
