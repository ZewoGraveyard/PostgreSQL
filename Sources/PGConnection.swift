import libpq
import SwiftSQL


public class PGConnection : Connection {
    public enum Error : ErrorType {
        case ConnectFailed(reason: String)
        case ExecutionError(reason: String)
    }
    
    public enum Status {
        case Bleg
    }
    
    public class ConnectionInfo : SwiftSQL.ConnectionInfo, ConnectionInfoStringConvertible {
        
        public var connectionString: String {
            return "LOL"
        }
    }
    
    private var connection = COpaquePointer()
    
    deinit {
        close()
    }
    
    public var status: Status {
        return .Bleg
    }
    
    public func open(connectionInfo: ConnectionInfo) throws {
        connection = PQconnectdb(connectionInfo.connectionString)
        
        if let errorMessage = String.fromCString(PQerrorMessage(connection)) where !errorMessage.isEmpty {
            throw Error.ConnectFailed(reason: errorMessage)
        }
    }
    
    public func close() {
        PQfinish(connection)
    }
    
    
    public func openCursor(name: String, query: SwiftSQL.Query) throws {
        
    }
    
    public func closeCursor(name: String) throws {
        
    }
    
    public func execute(query: SwiftSQL.Query) throws -> PGResult {
        return PGResult(resultPointer:
            PQexec(connection, query.string)
        )
    }
}