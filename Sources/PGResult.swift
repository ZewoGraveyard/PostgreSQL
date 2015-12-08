//
//  PGResult.swift
//  SwiftPG
//
//  Created by David Ask on 08/12/15.
//  Copyright © 2015 Formbound. All rights reserved.
//

import libpq
import SwiftSQL

public class PGResult : Result {
    
    public enum Status : Int, ResultStatus {
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
            return true
        }
    }
    
    internal init(resultPointer: COpaquePointer) {
        self.resultPointer = resultPointer
    }
    
    deinit {
        clear()
    }
    
    public var status: Status {
        return Status(status: PQresultStatus(resultPointer))
    }
    
    private let resultPointer: COpaquePointer
    
    public func clear() {
        PQclear(resultPointer)
    }
    
    public var numberOfRows: Int {
        return Int(PQntuples(resultPointer))
    }
    
    public lazy var fieldNames: [String] = {
        let numFields = Int(PQnfields(self.resultPointer))
        
        var result: [String] = []
        result.reserveCapacity(numFields)
        
        for i in 0..<numFields {
            guard let fieldName = String.fromCString(PQfname(self.resultPointer, Int32(i))) else {
                continue
            }
            
            result.append(fieldName)
        }
        
        return result
    }()
}