@_exported import SQL
import Foundation
import CLibpq
import CLibvenice
import Axis

public struct ConnectionError: Error, CustomStringConvertible {
    public let description: String
}

public final class Connection: ConnectionProtocol {
    public typealias QueryRenderer = PostgreSQL.QueryRenderer

    public struct ConnectionInfo: ConnectionInfoProtocol {
        public var host: String
        public var port: Int
        public var databaseName: String
        public var username: String?
        public var password: String?
        public var options: String?

        public init?(uri: URL) {
            do {
                try self.init(uri)
            } catch {
                return nil
            }
        }

        public init(_ uri: URL) throws {
            let databaseName = uri.path.trim(["/"])

            guard let host = uri.host, let port = uri.port else {
                throw ConnectionError(description: "Failed to extract host, port, database name from URI")
            }

            self.host = host
            self.port = port
            self.databaseName = databaseName
            self.username = uri.user
            self.password = uri.password
        }

        public init(host: String, port: Int = 5432, databaseName: String, username: String? = nil, password: String? = nil, options: String? = nil) {
            self.host = host
            self.port = port
            self.databaseName = databaseName
            self.username = username
            self.password = password
            self.options = options
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
    private var fd: Int32 = -1

    public let connectionInfo: ConnectionInfo

    public required init(info: ConnectionInfo) {
        self.connectionInfo = info
    }

    deinit {
        close()
    }

    public var internalStatus: InternalStatus {
        return InternalStatus(status: PQstatus(self.connection))
    }

    public func open() throws {
        guard connection == nil else {
            throw ConnectionError(description: "Connection already opened.")
        }
        
        var components = URLComponents()
        components.scheme = "postgres"
        components.host = connectionInfo.host
        components.port = connectionInfo.port
        components.user = connectionInfo.username
        components.password = connectionInfo.password
        components.path = "/\(connectionInfo.databaseName)"
        if let options = connectionInfo.options {
            components.queryItems = [URLQueryItem(name: "options", value: options)]
        }
        let url = components.url!.absoluteString
        
        connection = PQconnectStart(url)
        
        guard connection != nil else {
            throw ConnectionError(description: "Could not allocate connection.")
        }
        
        guard PQstatus(connection) != CONNECTION_BAD else {
            throw ConnectionError(description: "Could not start connection.")
        }
        
        fd = PQsocket(connection)
        guard fd >= 0 else {
            throw mostRecentError ?? ConnectionError(description: "Could not get file descriptor.")
        }

        loop: while true {
            let status = PQconnectPoll(connection)
            switch status {
            case PGRES_POLLING_OK:
                break loop
            case PGRES_POLLING_READING:
                mill_fdwait(fd, FDW_IN, 15.seconds.fromNow().int64milliseconds, nil)
                fdclean(fd)
            case PGRES_POLLING_WRITING:
                mill_fdwait(fd, FDW_OUT, 15.seconds.fromNow().int64milliseconds, nil)
                fdclean(fd)
            case PGRES_POLLING_ACTIVE:
                break
            case PGRES_POLLING_FAILED:
                throw mostRecentError ?? ConnectionError(description: "Could not connect to Postgres Server.")
            default:
                break
            }
        }
        
        guard PQsetnonblocking(connection, 1) == 0 else {
            throw mostRecentError ?? ConnectionError(description: "Could not set to non-blocking mode.")
        }
        
        guard PQstatus(connection) == CONNECTION_OK else {
            throw mostRecentError ?? ConnectionError(description: "Could not connect to Postgres Server.")
        }
    }

    public var mostRecentError: ConnectionError? {
        guard let errorString = String(validatingUTF8: PQerrorMessage(connection)), !errorString.isEmpty else {
            return nil
        }

        return ConnectionError(description: errorString)
    }

    public func close() {
        if connection != nil {
            PQfinish(connection!)
            connection = nil
        }
    }

    public func createSavePointNamed(_ name: String) throws {
        try execute("SAVEPOINT ?", parameters: [.string(name)])
    }

    public func rollbackToSavePointNamed(_ name: String) throws {
        try execute("ROLLBACK TO SAVEPOINT ?", parameters: [.string(name)])
    }

    public func releaseSavePointNamed(_ name: String) throws {
        try execute("RELEASE SAVEPOINT ?", parameters: [.string(name)])
    }

    @discardableResult
    public func execute(_ statement: String, parameters: [Value?]?) throws -> Result {
        var statement = statement.sqlStringWithEscapedPlaceholdersUsingPrefix("$") {
            return String($0 + 1)
        }

        defer { logger?.debug(statement) }

        var parameterData = [UnsafePointer<Int8>?]()
        var deallocators = [() -> ()]()
        defer { deallocators.forEach { $0() } }

        if let parameters = parameters {
            for parameter in parameters {

                guard let value = parameter else {
                    parameterData.append(nil)
                    continue
                }

                let data: AnyCollection<Int8>
                switch value {
                case .buffer(let value):
                    data = AnyCollection(value.map { Int8($0) })

                case .string(let string):
                    data = AnyCollection(string.utf8CString)
                }

                let pointer = UnsafeMutablePointer<Int8>.allocate(capacity: Int(data.count))
                deallocators.append {
                    pointer.deallocate(capacity: Int(data.count))
                }

                for (index, byte) in data.enumerated() {
                    pointer[index] = byte
                }

                parameterData.append(pointer)
            }
        }

        let sendResult: Int32 = parameterData.withUnsafeBufferPointer { buffer in
            if buffer.isEmpty {
                return PQsendQuery(self.connection, statement)
            } else {
                return PQsendQueryParams(self.connection,
                                         statement,
                                         Int32(parameterData.count),
                                         nil,
                                         buffer.baseAddress!,
                                         nil,
                                         nil,
                                         0)
            }
        }

        guard sendResult == 1 else {
            throw mostRecentError ?? ConnectionError(description: "Could not send query.")
        }

        // write query
        while true {
            mill_fdwait(fd, FDW_OUT, -1, nil)
            fdclean(fd)
            let status = PQflush(connection)
            guard status >= 0 else {
                throw mostRecentError ?? ConnectionError(description: "Could not send query.")
            }
            guard status == 0 else {
                continue
            }
            break
        }

        // read response
        var lastResult: OpaquePointer? = nil
        while true {
            guard PQconsumeInput(connection) == 1 else {
                throw mostRecentError ?? ConnectionError(description: "Could not send query.")
            }

            guard PQisBusy(connection) == 0 else {
                mill_fdwait(fd, FDW_IN, -1, nil)
                fdclean(fd)
                continue
            }

            guard let result = PQgetResult(connection) else {
                break
            }

            if lastResult != nil {
                PQclear(lastResult!)
                lastResult = nil
            }

            let status = PQresultStatus(result)
            guard status == PGRES_COMMAND_OK || status == PGRES_TUPLES_OK else {
                throw mostRecentError ?? ConnectionError(description: "Query failed.")
            }

            lastResult = result
        }

        guard lastResult != nil else {
            throw mostRecentError ?? ConnectionError(description: "Query failed.")
        }
        return try Result(lastResult!)
    }
}

extension Collection where Iterator.Element == String {
    
    func withUnsafeCStringArray<T>(_ body: (UnsafePointer<UnsafePointer<Int8>?>) throws -> T) rethrows -> T {
        var pointers: [UnsafePointer<Int8>?] = []
        var deallocators: [() -> ()] = []
        defer {
            for deallocator in deallocators {
                deallocator()
            }
        }
        
        for string in self {
            string.utf8CString.withUnsafeBufferPointer {
                let count = $0.count
                if count > 0 {
                    let copy = UnsafeMutablePointer<Int8>.allocate(capacity: count)
                    deallocators.append { copy.deallocate(capacity: count) }
                    memcpy(copy, $0.baseAddress!, count)
                    pointers.append(copy)
                } else {
                    pointers.append(nil)
                }
            }
        }
        
        return try pointers.withUnsafeBufferPointer {
            try body($0.baseAddress!)
        }
    }

}
