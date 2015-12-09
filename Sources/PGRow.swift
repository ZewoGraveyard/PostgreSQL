//
//  PGRow.swift
//  SwiftPG
//
//  Created by David Ask on 09/12/15.
//  Copyright © 2015 Formbound. All rights reserved.
//

import SwiftSQL

public struct PGRow {
    public struct Value : RowValue {
        
        public let stringValue: String?
        
        internal init(stringValue: String) {
            self.stringValue = stringValue
        }
        
        public var integerValue: Int? {
            guard let string = stringValue else {
                return nil
            }
            
            return Int(string)
        }
        
        public var doubleValue: Double? {
            guard let string = stringValue else {
                return nil
            }
            
            return Double(string)
        }
    }
    
    internal init(valuesByName: [String: Value?]) {
        self.valuesByName = valuesByName
    }
    
    private var valuesByName: [String: Value?]
    
    public subscript(fieldName: String) -> Value? {
        if let value = valuesByName[fieldName] {
            return value
        }
        
        return nil
    }
}
