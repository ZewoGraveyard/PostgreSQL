//
//  PGResult.swift
//  SwiftPG
//
//  Created by David Ask on 08/12/15.
//  Copyright © 2015 Formbound. All rights reserved.
//

import libpq
import SwiftSQL

public class PGResult: Result {
    
    
    public enum Error : ErrorType {
        case BadStatus(String)
    }
    
    public enum Status: Int, ResultStatus {
        case EmptyQuery
        case CommandOK
        case TuplesOK
        case CopyOut
        case CopyIn
        case BadResponse
        case NonFatalError
        case FatalError
        case CopyBoth
        case SingleTuple
        case Unknown
        
        public init(status: ExecStatusType) {
            switch status {
            case PGRES_EMPTY_QUERY:
                self = .EmptyQuery
                break
            case PGRES_COMMAND_OK:
                self = .CommandOK
                break
            case PGRES_TUPLES_OK:
                self = .TuplesOK
                break
            case PGRES_COPY_OUT:
                self = .CopyOut
                break
            case PGRES_COPY_IN:
                self = .CopyIn
                break
            case PGRES_BAD_RESPONSE:
                self = .BadResponse
                break
            case PGRES_NONFATAL_ERROR:
                self = .NonFatalError
                break
            case PGRES_FATAL_ERROR:
                self = .FatalError
                break
            case PGRES_COPY_BOTH:
                self = .CopyBoth
                break
            case PGRES_SINGLE_TUPLE:
                self = .SingleTuple
                break
            default:
                self = .Unknown
                break
            }
        }
        
        public var successful: Bool {
            return self != .BadResponse && self != .FatalError
        }
    }
    
    internal init(resultPointer: COpaquePointer) throws {
        self.resultPointer = resultPointer
        
        guard status.successful else {
            throw Error.BadStatus(String.fromCString(PQresultErrorMessage(resultPointer)) ?? "No error message")
        }
    }
    
    deinit {
        clear()
    }
    
    public typealias Generator = AnyGenerator<PGRow>
    
    public func generate() -> Generator {
        var index: Int = 0
        return anyGenerator {
            guard index < self.count else {
                return nil
            }
            
            defer {
                index += 1
            }
            
            return self[index]
        }
    }
    
    public subscript(index: Int) -> PGRow {
        let index = Int32(index)
        
        var result: [String: PGRow.Value?] = [:]
        
        for (fieldIndex, field) in fields.enumerate() {
            let fieldIndex = Int32(fieldIndex)
            
            if PQgetisnull(resultPointer, index, fieldIndex) == 1 {
                result[field.name] = nil
            }
            else {
                
                guard let string = String.fromCString(PQgetvalue(resultPointer, index, fieldIndex)) else {
                    result[field.name] = nil
                    continue
                }
                
                result[field.name] = PGRow.Value(stringValue: string)
            }
        }
        
        return PGRow(valuesByName: result)
    }
    
    public var count: Int {
        return Int(PQntuples(self.resultPointer))
    }
    
    lazy public var countAffected: Int = {
        guard let str = String.fromCString(PQcmdTuples(self.resultPointer)) else {
            return 0
        }
        
        return Int(str) ?? 0
    }()
    
    public var status: Status {
        return Status(status: PQresultStatus(resultPointer))
    }
    
    private let resultPointer: COpaquePointer
    
    public func clear() {
        PQclear(resultPointer)
    }
    
    
    public lazy var fields: [PGField] = {
        var result: [PGField] = []
        
        for i in 0..<PQnfields(self.resultPointer) {
            guard let fieldName = String.fromCString(PQfname(self.resultPointer, i)) else {
                continue
            }
            
            result.append(
                PGField(name: fieldName)
            )
        }
        
        return result
        
    }()
}