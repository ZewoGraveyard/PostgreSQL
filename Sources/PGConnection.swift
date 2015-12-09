import libpq
import SwiftSQL


public class PGConnection: Connection {
    public enum Error: ErrorType {
        case ConnectFailed(reason: String)
        case ExecutionError(reason: String)
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
    
    public struct Info: SwiftSQL.ConnectionInfo {
        
        public var user: String?
        public var password: String?
        public var host: String
        public var port: UInt = 5432
        public var database: String
        
        public var connectionString: String {
            
            var userInfo = ""
            if let user = user {
                userInfo = user
                
                if let password = password {
                    userInfo += ":\(password)@"
                }
                else {
                  userInfo += "@"
                }
            }
            
            return "postgres://\(userInfo)\(host):\(port)/\(database)"
        }
        
        public init(host: String, database: String, port: UInt = 5432, user: String? = nil, password: String? = nil) {
            self.user = user
            self.password = password
            self.host = host
            self.port = port
            self.database = database
        }
        
        public init(connectionString: String) {
            fatalError("Sorry, URL parsing is not available at the moment")
        }
        
        public init(stringLiteral: String) {
            self.init(connectionString: stringLiteral)
        }
        
        public init(unicodeScalarLiteral value: String) {
            self.init(stringLiteral: value)
        }
        
        public init(extendedGraphemeClusterLiteral value: String) {
            self.init(stringLiteral: value)
        }
    }
    
    private(set) public var connectionInfo: Info
    
    private var connection: COpaquePointer = nil
    
    public var status: Status {
        return Status(status: PQstatus(self.connection))
    }
    
    public required init(_ connectionInfo: Info) {
        self.connectionInfo = connectionInfo
    }
    
    deinit {
        close()
    }
    
    public func open() throws {
        connection = PQconnectdb(connectionInfo.connectionString)
        
        while status != .OK && status != .Bad {
            sleep(1)
        }
        
        if let errorMessage = String.fromCString(PQerrorMessage(connection)) where !errorMessage.isEmpty {
            throw Error.ConnectFailed(reason: errorMessage)
        }
    }
    
    public func close() {
        PQfinish(connection)
        connection = nil
    }
    
    public func openCursor(name: String) throws {
        try self.execute("OPEN %@", arguments: name)
    }
    
    public func closeCursor(name: String) throws {
        try self.execute("CLOSE %@", arguments: name)
    }
    
    
    public func execute(string: String, arguments: CVarArgType...) throws -> PGResult {
        return try PGResult(
            resultPointer: PQexec(connection, string)
        )
    }
    
    public func execute(string: String, arguments: [CVarArgType]) throws -> PGResult {
        return try PGResult(
            resultPointer: PQexec(connection, string)
        )
    }
}