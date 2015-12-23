// Value.swift
//
// The MIT License (MIT)
//
// Copyright (c) 2015 Formbound
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import SQL
import Core
import CLibpq

public struct Point: SQLParameterConvertible {
    public let x: Double
    public let y: Double
    
    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
    
    public var SQLParameterData: SQLParameterConvertibleType {
        return .Text("(\(x),\(y))")
    }
}

public struct Value: SQL.Value  {

    public let data: Data

    public init(data: Data) {
        self.data = data
    }
    
    public var point: Point? {
        guard let string = string else {
            return nil
        }
        
        let stringValues = string.stringByTrimmingCharactersInSet(
            Set<Character>(["(", ")", " "])
            ).splitBy(",")
        
        guard
            stringValues.count == 2,
            let x = Double(stringValues[0]),
            let y = Double(stringValues[1])
            else {
                return nil
        }
        
        return Point(x: x, y: y)
        
    }
}
