@_exported import SQL
import CLibpq

public final class Connection: ConnectionProtocol {
    public typealias QueryRenderer = PostgreSQL.QueryRenderer

    public struct Error: ErrorProtocol, CustomStringConvertible {
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
        public init(host: String, port: Int = 5432, databaseName: String, password: String? = nil, options: String? = nil, tty: String? = nil) {
            self.host = host
            self.port = port
            self.databaseName = databaseName
            self.password = password
            self.options = options
            self.tty = tty
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

    public func execute(_ statement: String, parameters: [Value?]?) throws -> Result {

        var statement = statement.sqlStringWithEscapedPlaceholdersUsingPrefix("$") {
            return String($0 + 1)
        }

        defer { logger?.debug(statement) }

        guard let parameters = parameters else {
            guard let resultPointer = PQexec(connection, statement) else {
                throw mostRecentError ?? Error(description: "Empty result")
            }

            return try Result(resultPointer)
        }

        var parameterData = [[UInt8]?]()

        for parameter in parameters {

            guard let value = parameter else {
                parameterData.append(nil)
                continue
            }

            switch value {
            case .data(let data):
                parameterData.append(Array(data))
                break
            case .string(let string):
                parameterData.append(Array(string.utf8) + [0])
                break
            }
        }


        guard let result:OpaquePointer = PQexecParams(
            self.connection,
            statement,
            Int32(parameters.count),
            nil,
            parameterData.map { UnsafePointer<Int8>($0) },
            nil,
            nil,
            0
            ) else {
                throw mostRecentError ?? Error(description: "Empty result")
        }

        return try Result(result)
    }
}
