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
import CLibpq

public final class Connection: ConnectionProtocol {
    
    public struct Error: ErrorProtocol {
        public let description: String
    }
    
    public struct ConnectionInfo: ConnectionInfoProtocol {
        public var host: String
        public var port: Int
        public var databaseName: String
        public var username: String?
        public var password: String?
        public var options: String?
        public var tty: String?
        
        public init(_ uri: URI) throws {
            
            guard let host = uri.host, port = uri.port, databaseName = uri.path?.trim(["/"]) else {
                throw Error(description: "Failed to extract host, port, database name from URI")
            }
            
            self.host = host
            self.port = port
            self.databaseName = databaseName
            self.username = uri.userInfo?.username
            self.password = uri.userInfo?.password

        }
    }
    
    
    public enum InternalStatus {
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
    
    public var logger: Logger?
    
    private var connection: OpaquePointer? = nil
    
    public let connectionInfo: ConnectionInfo
    
    public required init(_ info: ConnectionInfo) {
        self.connectionInfo = info
    }
    
    deinit {
        close()
    }
    
    public var internalStatus: InternalStatus {
        return InternalStatus(status: PQstatus(self.connection))
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
    
    public func createSavePointNamed(_ name: String) throws {
        try execute("SAVEPOINT \(name)")
    }
    
    public func rollbackToSavePointNamed(_ name: String) throws {
        try execute("ROLLBACK TO SAVEPOINT \(name)")
    }
    
    public func releaseSavePointNamed(_ name: String) throws {
        try execute("RELEASE SAVEPOINT \(name)")
    }
    
    public func executeInsertQuery<T: SQLDataConvertible>(query: InsertQuery, returningPrimaryKeyForField primaryKey: DeclaredField) throws -> T {
        var components = query.queryComponents
        components.append(QueryComponents(strings: ["RETURNING", primaryKey.qualifiedName, "AS", "returned__pk"]))
        
        let result = try execute(components)
        
        guard let pk: T = try result.first?.value("returned__pk") else {
            throw Error(description: "Did not receive returned primary key")
        }
        
        return pk
    }
    
    public func execute(_ components: QueryComponents) throws -> Result {
        
        defer { logger?.debug(components.description) }
        
        let result: OpaquePointer
        
        if components.values.isEmpty {
            result = PQexec(connection, components.string)
        }
        else {
            let values = UnsafeMutablePointer<UnsafePointer<Int8>?>(allocatingCapacity: components.values.count)
            
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
                try components.stringWithEscapedValuesUsingPrefix("$") {
                    index, _ in
                    return String(index + 1)
                },
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
