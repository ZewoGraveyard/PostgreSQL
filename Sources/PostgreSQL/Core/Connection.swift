// Connection.swift
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


@_exported import SQL
import Venice
import CLibpq

public class Connection: SQL.Connection {
    public struct Error: ErrorProtocol {
        public let description: String
    }
    
    public struct Info: ConnectionInfo {
        public var host: String
        public var port: Int
        public var databaseName: String
        public var username: String?
        public var password: String?
        public var options: String?
        public var tty: String?
    }
    
    
    public enum Status {
        case Bad
        case Started
        case Made
        case AwatingResponse
        case AuthOK
        case SettingEnvironment
        case SSLStartup
        case OK
        case Unknown
        case Needed
        
        public init(status: ConnStatusType) {
            switch status {
            case CONNECTION_NEEDED:
                self = .Needed
                break
            case CONNECTION_OK:
                self = .OK
                break
            case CONNECTION_STARTED:
                self = .Started
                break
            case CONNECTION_MADE:
                self = .Made
                break
            case CONNECTION_AWAITING_RESPONSE:
                self = .AwatingResponse
                break
            case CONNECTION_AUTH_OK:
                self = .AuthOK
                break
            case CONNECTION_SSL_STARTUP:
                self = .SSLStartup
                break
            case CONNECTION_SETENV:
                self = .SettingEnvironment
                break
            case CONNECTION_BAD:
                self = .Bad
                break
            default:
                self = .Unknown
                break
            }
        }
    }
    
    public var log: Log? = nil
    
    private(set) public var connectionInfo: Info
    
    private var connection: OpaquePointer = nil
    
    public var status: Status {
        return Status(status: PQstatus(self.connection))
    }
    
    public convenience init(host: String, port: Int = 5432, databaseName: String, username: String? = nil, password: String? = nil, options: String? = nil, tty: String? = nil) {
        self.init(Info(host: host, port: port, databaseName: databaseName, username: username, password: password, options: options, tty: tty))
    }
    
    public required init(_ info: Info) {
        self.connectionInfo = info
    }
    
    deinit {
        close()
    }
    
    public func open() throws {
        connection = PQsetdbLogin(
            connectionInfo.host,
            String(connectionInfo.port),
            connectionInfo.options ?? "",
            connectionInfo.tty ?? "",
            connectionInfo.databaseName,
            connectionInfo.username ?? "",
            connectionInfo.password ?? ""
        )
        
        if let error = mostRecentError {
            throw error
        }
    }
    
    public var mostRecentError: Error? {
        guard let errorString = String(validatingUTF8: PQerrorMessage(connection)) where !errorString.isEmpty else {
            return nil
        }
        
        return Error(description: errorString)
    }
    
    public func close() {
        PQfinish(connection)
        connection = nil
    }
    
    public func createSavePointNamed(name: String) throws {
        try execute("SAVEPOINT \(name)")
    }
    
    public func rollbackToSavePointNamed(name: String) throws {
        try execute("ROLLBACK TO SAVEPOINT \(name)")
    }
    
    public func releaseSavePointNamed(name: String) throws {
        try execute("RELEASE SAVEPOINT \(name)")
    }
    
    public func execute(components: QueryComponents) throws -> Result {
        
        defer {
            log?.debug(components.description)
        }
        
        let result: OpaquePointer
        
        if components.values.isEmpty {
            result = PQexec(connection, components.string)
        }
        else {
            let values = UnsafeMutablePointer<UnsafePointer<Int8>>(allocatingCapacity: components.values.count)
            
            defer {
                values.deinitialize()
                values.deallocateCapacity(components.values.count)
            }
            
            var temps = [Array<UInt8>]()
            for (i, parameter) in components.values.enumerated() {
                
                guard let value = parameter else {
                    temps.append(Array<UInt8>("NULL".utf8) + [0])
                    values[i] = UnsafePointer<Int8>(temps.last!)
                    continue
                }
                
                switch value {
                case .Binary(let data):
                    values[i] = UnsafePointer<Int8>(Array(data))
                    break
                case .Text(let string):
                    temps.append(Array<UInt8>(string.utf8) + [0])
                    values[i] = UnsafePointer<Int8>(temps.last!)
                    break
                }
            }
            
            result = PQexecParams(
                self.connection,
                try components.stringWithNumberedValuesUsingPrefix("$"),
                Int32(components.values.count),
                nil,
                values,
                nil,
                nil,
                0
            )
        }
        
        return try Result(result)
    }
}