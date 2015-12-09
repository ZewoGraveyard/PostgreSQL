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
    
    private var rowIndex: Int32 = 0
    
    public func next() -> PGRow? {
        
        guard rowIndex < Int32(numberOfRows) else {
            return nil
        }
        
        var result: [String: PGRow.Value?] = [:]
        
        for (key, index) in fieldIndexByName {
            
            let index = Int32(index)
            
            if PQgetisnull(resultPointer, rowIndex, index) == 1 {
                result[key] = nil
            }
            else {
                
                guard let string = String.fromCString(PQgetvalue(resultPointer, rowIndex, index)) else {
                    result[key] = nil
                    continue
                }
                
                result[key] = PGRow.Value(stringValue: string)
            }
        }
        
        rowIndex += 1
        
        return PGRow(valuesByName: result)
    }
    
    public var status: Status {
        return Status(status: PQresultStatus(resultPointer))
    }
    
    private let resultPointer: COpaquePointer
    
    public func clear() {
        PQclear(resultPointer)
    }
    
    public lazy var numberOfRows: Int = {
        return Int(PQntuples(self.resultPointer))
    }()
    
    public lazy var numberOfFields: Int = {
        return Int(PQnfields(self.resultPointer))
    }()
    
    public lazy var fieldNames: [String] = {
        return Array(self.fieldIndexByName.keys)
    }()
    
    public lazy var numberOfRowsAffected: Int = {
        guard let str = String.fromCString(PQcmdTuples(self.resultPointer)) else {
            return 0
        }
        
        return Int(str) ?? 0
    }()
    
    public lazy var fieldIndexByName: [String: Int] = {
        
        var result: [String: Int] = [:]
        
        for i in 0..<self.numberOfFields {
            guard let fieldName = String.fromCString(PQfname(self.resultPointer, Int32(i))) else {
                continue
            }
            
            result[fieldName] = i
        }
        
        return result
    }()
}